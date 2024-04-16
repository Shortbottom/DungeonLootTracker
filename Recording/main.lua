local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class RecordsDB: AceModule
local rDB = addon:GetModule("RecordsDB")

---@class ShortyUtil: AceModule
local ShortyUtil = addon:GetModule("ShortyUtil")

---@class Events: AceModule
local events = addon:GetModule("Events")

---@class Recording: AceModule
local recording = addon:NewModule("Recording")

LibStub("AceEvent-3.0"):Embed(recording)

---@class Message: AceMessage
local messagesToRegister = {
  ["recording/startRecording"] = "startNewRecording",
  ["recording/stopRecording"] = "stopRecording",
  ["recording/showList"] = "showList",
  ["recording/lootReady"] = "lootReady",
  ["recording/lootClosed"] = "lootClosed",
  ["recording/lootSlotCleared"] = "lootSlotCleared"
}

local lootTable = lootTable or {}

function recording:OnInitialize()
  -- Info: Messages are what the AddOn use to trigger internal events
  for k, v in pairs(messagesToRegister) do
    recording:RegisterMessage(k, v)
  end

  -- Hide the stop recording button
  _G["DLT_Parent_StopRecordingBtn"]:Hide()
end

---When the player loots, we want to go through and find out what there was and make an entry in the table
---@param n number The number of items (incl. gold being looted)
---@param t table The table containing everything that is being looted
---@return boolean
function recording:collectLoot(n, t)
end

function recording:startNewRecording(x, ...)
  local self, t = x, ...
  local startBtn = _G["DLT_Parent_StartRecordingBtn"]
  local stopBtn = _G["DLT_Parent_StopRecordingBtn"]

  if DLT_Parent_.recording == true then return end -- In case somehow recording has started we don't want to try and start recording again

  addon:Print("Started Recording")

  DLT_Parent_.recording = true
  startBtn:Hide()
  stopBtn:Show()

  local newID = rDB:GetNewID()
  local instanceName, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID
  local isInstance, _ = IsInInstance()

  if isInstance then
    instanceName, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
  else
    -- Player isn't in an instance, so we need to get the various information a different way
    instanceID = C_Map.GetBestMapForUnit("player")
    difficultyID = 0                                         -- Since we're not in an instance just set to 0 for disabled
  end
  local recordStartTime = C_DateAndTime.GetServerTimeLocal() -- We will get the date and time from this
  local recordEndTime = 0
  local playerMoney = GetMoney()

  -- INFO: We need to save the record to the database
  ---@type RecordList
  local t = {
    recordID = newID,
    instanceID = instanceID,
    isInstance = isInstance,
    difficultyID = difficultyID,
    startTime = recordStartTime,
    endTime = 0,
    timeDiff = 0,
    playerMoneyStart = playerMoney,
    playerMoneyEnd = 0,
    playerMoneyDiff = 0,
    items = {}
  }

  rDB:SaveNewRecord(newID, t)

  -- Think we should just tell the events module to register the events
  events:startRecording_Events()
end

--- Stops the recording process.
---@param ... varargs A number of args passed.
function recording:stopRecording(...)
  local startBtn = _G["DLT_Parent_StartRecordingBtn"]
  local stopBtn = _G["DLT_Parent_StopRecordingBtn"]
  if DLT_Parent_.recording ~= true then return end -- Can't stop recording if we aren't recording in the first place

  addon:Print("Stop Recording")
  DLT_Parent_.recording = false
  startBtn:Show()
  stopBtn:Hide()
  local currentRecID = addon.currentRecID

  if (type(currentRecID) == "number") and (currentRecID > 0) then
    local x = rDB:GetIndex(currentRecID)
    local tbl = rDB.data.records[x]
    local s, e = tbl.startTime, C_DateAndTime.GetServerTimeLocal()
    tbl.endTime = e
    tbl.timeDiff = ShortyUtil:convertSecsToReadable(e - s)

    -- Record the Player's money at the end of the recording so we can track how much they made
    local playerMoney = GetMoney()
    tbl.playerMoneyEnd = playerMoney
    tbl.playerMoneyDiff = playerMoney - tbl.playerMoneyStart

    -- I: If the player has chosen to print the amount of gold earned during the recording then we will do so
    if DB.GetPrintMoneyEarned() then
      if tbl.playerMoneyDiff == 0 then
        addon:Print("You didn't earn anything during this recording")
      else
        addon:Print("Earned during this recording: ", GetMoneyString(tbl.playerMoneyDiff, true))
      end
    end
  else
    -- ! If we end up in here then there has been some sort of error
    error("No Currrent Rec ID:- Got(" .. (currentRecID == nil and "nil" or currentRecID) .. ")", 1)
  end

  -- INFO: The last thing we want to do is stop listening to the events
  events:stopRecording_Events()
end

function recording:showList(x, ...)
  addon:Print("Showing List")
end

function recording:lootReady()
  addon:Print("Updating the Loot Table")
  local n = GetNumLootItems()
  addon:Print("n: ", n)
  lootTable = GetLootInfo()
  addon:Print(ShortyUtil:table_to_json(lootTable))
end

-- We will loop through the loot and add it to the table
function recording:lootSlotCleared()
  local recordID = addon.currentRecID
  local n = GetNumLootItems()
  local info = GetLootInfo()

  for i, slot in pairs(info) do
    local lootType = GetLootSlotType(i)
    local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(i)
    -- We are only interested if this isn't money
    if lootType ~= Enum.LootSlotType.Money then
      addon:Print("Looting items")
    end
    local itemLink = GetLootSlotLink(i)
  end

  --local x = recording:collectLoot(n, t)
end

function recording:lootClosed()
  addon:Print("Loot Closed")
end

local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local const = addon:GetModule("Constants")

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class RecordsDB: AceModule
local rDB = addon:GetModule("RecordsDB")

---@class ShortyUtil: AceModule
local ShortyUtil = addon:GetModule("ShortyUtil")

---@class Events: AceModule
local events = addon:GetModule("Events")

---@class Locales: AceModule
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

---@class Recording: AceMessage
local recording = addon:NewModule("Recording")

LibStub("AceEvent-3.0"):Embed(recording)

local messagesToRegister = {
  ["recording/startRecording"] = "startNewRecording",
  ["recording/stopRecording"] = "stopRecording",
  ["recording/showList"] = "showList",
  ["recording/lootReady"] = "lootReady",
  ["recording/lootClosed"] = "lootClosed",
  ["recording/lootSlotCleared"] = "lootSlotCleared"
}

-- ---@type table
-- local lootTable = lootTable or {}

function recording:OnInitialize()
  -- Info: Messages are what the AddOn use to trigger internal events
  for k, v in pairs(messagesToRegister) do
    recording:RegisterMessage(k, v)
  end

  -- Hide the stop recording button
  _G["DLT_Parent_StopRecordingBtn"]:Hide()

  addon.currentLootTable = {}
end

function recording:startNewRecording(x, ...)
  local _, _ = x, ...
  local startBtn = _G["DLT_Parent_StartRecordingBtn"]
  local stopBtn = _G["DLT_Parent_StopRecordingBtn"]

  if DLT_Parent_.recording == true then return end -- In case somehow recording has started we don't want to try and start recording again

  addon:Print("Started Recording")

  DLT_Parent_.recording = true
  startBtn:Hide()
  stopBtn:Show()

  local newID = rDB:GetNewID()



  --[[@do-not-package@--]]
  ---@diagnostic disable-next-line: unused-local --@end-do-not-package@
  local instanceName, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID
  local isInstance, _ = IsInInstance()

  if isInstance then
    ---@diagnostic disable-next-line: unused-local
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
    endTime = recordEndTime,
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
function recording:stopRecording()
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

    --#region Record Money
    -- INFO: We can record how much money the player has received during the recording here, only issue would be that
    -- INFO: this would also record any money they have collected from mail (AH sales inc.) or other sources that aren't
    -- INFO: directly related to the recording.
    -- Question: What should we count as money earned during the recording? Immediate answer is any looted money
    -- Question: and money from selling items to a vendor. How would we know if an item was sold on the AH?
    -- Question: Surely an item looted during a recording and sold on the AH after the recording should be counted?
    -- * For the moment I think i'll just accrue the money as they loot it.
    -- Record the Player's money at the end of the recording so we can track how much they made
    --[[
      local playerMoney = GetMoney()
      tbl.playerMoneyEnd = playerMoney
      tbl.playerMoneyDiff = playerMoney - tbl.playerMoneyStart

      -- Info: If the player has chosen to print the amount of gold earned during the recording then we will do so
      if DB.GetPrintMoneyEarned() then
        if tbl.playerMoneyDiff == 0 then
          addon:Print("You didn't earn anything during this recording")
        else
          addon:Print("Earned during this recording: ", GetMoneyString(tbl.playerMoneyDiff, true))
        end
      end
      --]]
    --#endregion
  else
    -- ! If we end up in here then there has been some sort of error
    error("No Current Rec ID:- Got(" .. (currentRecID == nil and "nil" or currentRecID) .. ")", 1)
  end

  -- INFO: The last thing we want to do is stop listening to the events
  events:stopRecording_Events()
end

function recording:showList(_x, _)
  addon:Print("Showing List")
end

function recording:lootReady()
  addon:Print("Loot Ready")
  local lootTable = GetLootInfo() or {}
  addon.lootTable = recording:BuildLootTable(lootTable)
end

-- We will loop through the loot and add it to the table
function recording:lootSlotCleared(_, slot)
  if addon.lastSlotLooted == slot then return end -- We have already looted this slot
  addon:Print("Loot Slot Cleared: ", slot)        -- Slot that was looted

  local _recordID = addon.currentRecID            -- RecordID that we need to add the loot to
end

function recording:lootClosed()
  addon:Print("Loot Closed")
end

function recording:BuildLootTable(lootTable)
  addon.currentLootTable = lootTable or {}
  for slot = 1, GetNumLootItems() do
    -- Get info about this lootSlot
    ---@diagnostic disable-next-line: unused-local
    local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(slot)
    local _slotType = GetLootSlotType(slot)
    local _itemLink = GetLootSlotLink(slot)

    ---@class ItemList
    local item = const.RECORD_ITEM_DEFAULTS or {}
  end



  for slot, _v in pairs(lootTable) do
    ---@type number, number
    local item = {}
    ---@diagnostic disable-next-line: unused-local
    local itemID, itemType, itemSubType = 0, 0, 0
    ---@diagnostic disable-next-line: unused-local
    local lootIcon, lootName, itemQuantity, currencyID, itemQuality, _, _, _, _ = GetLootSlotInfo(slot)
    local classID, subClassID, value = 0, 0, 0
    ---@type LootSlotType
    local slotType = GetLootSlotType(slot)

    if (slotType == Enum.LootSlotType.Money) then
      itemID = 0
      value = ShortyUtil:convertMoneyToString(lootName) -- ? Should this be stored in quantity? or somewhere else?
      lootName = L["Money"]
    elseif (slotType == Enum.LootSlotType.Item) then
      local itemLink = GetLootSlotLink(slot)
      itemID, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemLink)
    elseif (slotType == Enum.LootSlotType.Currency) then -- This is for things like Honor, Conquest, etc
      itemID = currencyID                                -- currencyID is essentially the same as itemID is for items
    elseif (slotType == Enum.LootSlotType.None) then
      addon:Print(L["No Loot in Slot: "], slot)
    else
      addon:Print(L["Unknown Slot Type: "], slotType)
    end

    item.slotType = slotType
    item.itemID = itemID
    item.icon = lootIcon
    item.quality = itemQuality
    item.quantity = itemQuantity
    item.value = value -- TODO: Get the item from an AH addon if the player has one installed or maybe somewhere else
    item.keep = true   -- Info: Set to true so we don't accidentally vendor it. Vendoring it should be a conscious decision
    item.classID = classID
    item.subClassID = subClassID


    table.insert(addon.currentLootTable, slot, item)
  end
end

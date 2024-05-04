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
  ["recording/lootOpened"] = "lootOpened",
  ["recording/lootSlotChanged"] = "lootSlotChanged",
  ["recording/lootSlotCleared"] = "lootSlotCleared"
}

function recording:OnInitialize()
  -- Info: Messages are what the AddOn use to trigger internal events
  for k, v in pairs(messagesToRegister) do
    recording:RegisterMessage(k, v)
  end

  -- Hide the stop recording button
  _G["DLT_Parent_StopRecordingBtn"]:Hide()

  addon.currentLootTable = {}
end

function recording:ItemLooted()
  --addon:Print("Item Looted")
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

  local _instanceName, _instanceType, difficultyID, _difficultyName, _maxPlayers, _dynamicDifficulty, _isDynamic, instanceID, _instanceGroupSize, _LfgDungeonID
  local isInstance, _ = IsInInstance()

  if isInstance then
    _instanceName, _instanceType, difficultyID, _difficultyName, _maxPlayers, _dynamicDifficulty, _isDynamic, instanceID, _instanceGroupSize, LfgDungeonID =
        GetInstanceInfo()
  else
    -- Player isn't in an instance, so we need to get the various information a different way
    instanceID = C_Map.GetBestMapForUnit("player")
    difficultyID = 0                                         -- Since we're not in an instance just set to 0 for disabled
  end
  local recordStartTime = C_DateAndTime.GetServerTimeLocal() -- We will get the date and time from this
  local recordEndTime = 0
  local playerMoney = GetMoney()

  -- Set the table to initial values then we can overwrite them with the new values, this way it should always hold
  -- the correct values
  ---@type RecordList
  local t = const.RECORD_LIST_DEFAULTS
  t = {
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
    goldLooted = 0,
    items = {}
  }

  rDB:SaveNewRecord(newID, t)

  -- Tell the events module to register the events
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
    -- ! For the moment I think i'll just accrue the money as they loot it.
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
  --addon:Print("Loot Ready")
  addon.currentLootTable = {}
  for slot = 1, GetNumLootItems() do
    local lootIcon, lootName, lootQuantity, currencyID, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(slot)
    local slotType = GetLootSlotType(slot)
    local itemID, itemLink, value = 0, "", 0
    if slotType == Enum.LootSlotType.Money then
      value = ShortyUtil:ParseMoneyString(lootName)
    elseif slotType == Enum.LootSlotType.Item then
      itemLink = GetLootSlotLink(slot)
      local parsedItem = ShortyUtil:ParseItemLink(itemLink)
      itemID = parsedItem.itemID
    elseif slotType == Enum.LootSlotType.Currency then
      -- TODO: Add currency to the table
      addon:Print("Currency: ", lootName)
    elseif slotType == Enum.LootSlotType.None then
      addon:Print("No Loot in Slot: ", slot)
    end
    -- Set the item to the default values and then overwrite with the new values. This way we can be sure that the table will always have the correct keys|values
    local item = const.RECORD_ITEM_DEFAULTS
    item = {
      slotType = slotType,
      itemID = itemID,
      itemName = lootName,
      texture = lootIcon,
      quality = lootQuality,
      quantity = lootQuantity,
      value = value,
      keep = true,
      looted = false,
      currencyID = currencyID,
      locked = locked,
      isQuestItem = isQuestItem,
      questID = questID,
      isActive = isActive,
      classID = 0,
      subClassID = 0,
      itemLink = itemLink
    }
    if item then
      table.insert(addon.currentLootTable, item)
    end
  end
end

--- TODO: Check if the item already exists in the table and if it does then update the quantity
--- We will add the looted slot to the table
function recording:lootSlotCleared(_, slot)
  --addon:Print("Loot Slot Cleared: ", slot)

  -- Make sure we have a loot table to work from
  assert(addon.currentLootTable, "No Loot Table to work from.")

  -- We have already looted this slot, this is because if the item exists across multiple mobs the slot_cleared event will trigger for each mob
  if addon.lastSlotLooted == slot then return end

  local frameGoldLooted = _G["DLT_Parent_GoldLooted"]
  local recordID = addon.currentRecID -- RecordID that we need to add the loot to

  local slotInfo = addon.currentLootTable[slot]
  if slotInfo.slotType == const.LootSlotType.Money then -- If the slot is money then we need to add the value to the goldLooted
    slotInfo.looted = true                              -- We have looted the money
    slotInfo.keep = true                                -- We can't sell money
    addon.lastSlotLooted = slot
    rDB:SaveNewGoldLooted(recordID, slotInfo.value)
    frameGoldLooted:SetText(GetMoneyString(rDB:GetGoldLooted(recordID), true))
  elseif slotInfo.slotType == const.LootSlotType.Item then
    slotInfo.looted = true
    slotInfo.keep = true
    addon.lastSlotLooted = slot
    rDB:SaveNewItem(recordID, slotInfo)
  end
end

function recording:lootSlotChanged(_, slot)
  --addon:Print("recording:lootSlotChanged: ", slot)
  recording:UpdateLootTable(slot)
end

function recording:lootOpened()
  --addon:Print("Loot Opened")
  if #addon.currentLootTable == 0 then
    recording:lootReady()
  end
end

--[[
  ?? There doesn't seem to really be any real way other than looking at the chat_message to know if something was picked up<br>
  ?? Do I just assume if an item isn't in the loot table then it was picked up?<br>
  ?? Loot_Changed and Loot_Cleared also trigger if loot on a mob is not picked up and left to de-spawn<br>
  ?? Using the Chat_Loot_Message isn't guaranteed to work as the player could have it turned off and using it would require localisation support<br>
  ?? How likely is it that someone will have the loot window open and not loot long enough for the item to de-spawn?<br>
  Something has changed find out what
  Update the loot table with the new quantity of the item in the slot.
  Assume if it's not in the new loot table it's because it has been picked up
--]]
---@param slot number
function recording:UpdateLootTable(slot)
  --addon:Print("UpdateLootTable: ", slot)

  -- If the loot table is empty (meaning it has 0 entries/length) then we can't update anything
  if #addon.currentLootTable == 0 then return end

  -- Loop through our loot table to see if the slot is in there already
  local slotInfo
  for _, s in ipairs(addon.currentLootTable) do
    if s.slot == slot then
      slotInfo = s
    end
  end
  if slotInfo == nil then
    return
  end

  -- Get the new quantity of the item in the slot
  local oldQuantity = slotInfo.quantity
  local newQuantity = select(3, GetLootSlotInfo(slot))

  -- Check to see if the quantity has changed and if so figure out what is has changed by then update the table
  if newQuantity ~= oldQuantity then
    slotInfo.lastQuantityShift = oldQuantity - newQuantity
    slotInfo.quantity = newQuantity
  end
end

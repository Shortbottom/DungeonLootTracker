local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class RecordsDB: AceModule
local rDB = addon:GetModule("RecordsDB")

---@class ShortyUtil: AceModule
local ShortyUtil = addon:GetModule("ShortyUtil")

---@class Recording: AceModule
local recording = addon:NewModule("Recording")

LibStub("AceEvent-3.0"):Embed(recording)

---@class Events: AceModule
local events = addon:GetModule("Events")

---@class Message: AceMessage
local messagesToRegister = {
  ["recording/startRecording"] = "startNewRecording",
  ["recording/stopRecording"] = "stopRecording",
  ["recording/showList"] = "showList"
}

function recording:OnInitialize()
  -- events:RegisterMessage("recording/startRecording", function (self) recording:startNewRecording(self) end)
  -- events:RegisterMessage("recording/stopRecording", function (self) recording:stopRecording(self) end)
  -- events:RegisterMessage("recording/showList", function (self) recording:showList(self) end)

  for k, v in pairs(messagesToRegister) do
    recording:RegisterMessage(k, v)
  end

  -- Hide the stop recording button
  _G["DLT_Parent_StopRecordingBtn"]:Hide()
end

---When the player loots, we want to go through and find out what there was and make an entry in the table
---@param n number # The number of items (incl. gold being looted)
---@param t table # The table containing everything that is being looted
---@return boolean # Success or Failed
function recording:collectLoot(n, t)
  print(args)
end

function recording:startNewRecording(x, ...)
  local self, t = x, ...
  local startBtn = _G["DLT_Parent_StartRecordingBtn"]
  local stopBtn = _G["DLT_Parent_StopRecordingBtn"]

  if DLT_Parent_.recording == true then return end -- In case somehow recording has started we don't want to try and start recording again

  print("Started Recording")

  DLT_Parent_.recording = true
  startBtn:Hide()
  stopBtn:Show()

  -- Think we should just tell the events module to register the events
  events:startRecording_Events()

  --[[
    ? What info do we want to store for a recording?
    Mandatory Fields:
    Time
    Date Start and end maybe we could later on use this for more information reporting
    ZoneName (Could be a instance name or if player is in the outside world it could be a zone name)
    Gold We can just store a field to hold the gold that has been looted as this doesn't need a entry in the items table?
  --]]
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

  ---@type RecordList
  local t = {
    recordID = rDB:GetNewID(),
    instanceID = instanceID,
    isInstance = isInstance,
    difficultyID = difficultyID,
    recordStartTime = recordStartTime,
    recordEndTime = "",
    goldLooted = 0
  }
  ShortyUtil:tprint(t)
  --[[
  # This is where need to make a new List to add items too and register the loot events.
  # We don't want to be listening for the Loot Events unless we are recording
  --]]
end

function recording:stopRecording(x, ...)
  local startBtn = _G["DLT_Parent_StartRecordingBtn"]
  local stopBtn = _G["DLT_Parent_StopRecordingBtn"]
  if DLT_Parent_.recording ~= true then return end -- Can't stop recording if we aren't recording in the first place

  print("Stop Recording")
  DLT_Parent_.recording = false
  startBtn:Show()
  stopBtn:Hide()

  --[[
  * This is where need to finalise the List and unregister the loot events.
  * We don't want to be listening for the Loot Events unless we are recording
  --]]
  events:stopRecording_Events()
end

function recording:showList(x, ...)
  print("Showing List")
end

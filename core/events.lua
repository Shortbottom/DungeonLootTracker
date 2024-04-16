local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class ShortyUtil: AceModule
local ShortyUtil = addon:GetModule("ShortyUtil")

---@class Database: AceModule
local db = addon:GetModule("Database")

---@alias eventData any[][]

---@class Events: AceModule
---@field EventToRegister string # The blizzard event to listen for
---@field MethodToCall string # The method to call when the event happens
local _autoRecordEvents = {
  -- ["PLAYER_ENTERING_WORLD"] = "EnterWorld", -- This is the event we want to watch if autoRecord is true
  -- ["PLAYER_LEAVING_WORLD"] = "LeaveWorld"   -- This might be the better event to stop recording when autoRecord is true
}
local _recordingEvents = {
  ["LOOT_READY"] = function () addon:SendMessage("recording/lootReady") end,
  ["LOOT_CLOSED"] = function () addon:SendMessage("recording/lootClosed") end,
  ["LOOT_SLOT_CLEARED"] = function () addon:SendMessage("recording/lootSlotCleared") end
}

local events = addon:NewModule("Events")

LibStub("AceEvent-3.0"):Embed(events)

function events:OnInitialize()
  -- Register events to listen for
  -- for k, v in pairs(_autoRecordEvents) do
  --   events:RegisterEvent(k, v)
  -- end
end

function events:EnterWorld(event, initialLogin, reload, ...)
  local inInstance, instanceType = IsInInstance()

  if db:GetAutoRecord() then
    addon:Print("We want to autoRecord")
  end
  if ((initialLogin ~= true) and (reload ~= true)) then
    addon:Print("Entered an Instance")
  else
    addon:Print("Logged In or Reloading")
  end
end

function events:LeaveWorld(...)
  addon:Print("Leaving World: ", ...)
end

function events:OnDisable()
  for k, v in pairs(_eventsToRegiser) do
    events:UnRegisterEvent(k, v)
  end
end

function events:startRecording_Events()
  addon:Print("Listening to events")
  for k, v in pairs(_recordingEvents) do
    events:RegisterEvent(k, v)
  end
end

function events:stopRecording_Events()
  addon:Print("Stopping listening to events")
  for k, v in pairs(_recordingEvents) do
    events:UnregisterEvent(k, v)
  end
end

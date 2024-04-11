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
  ["LOOT_READY"] = "lootReady"
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
    print("We want to autoRecord")
  end
  if ((initialLogin ~= true) and (reload ~= true)) then
    print("Entered an Instance")
  else
    print("Logged In or Reloading")
  end
end

function events:LeaveWorld(...)
  print("Leaving World: ", ...)
end

function events:lootReady()
  local numItems = GetNumLootItems()
  print("numItems: ", numItems)
  local info = GetLootInfo()
  print("info: ", ShortyUtil:TableToString(info))
  print("LOOT AHOY")

  local x = recording:collectLoot(n, t)
end

function events:OnDisable()
  for k, v in pairs(_eventsToRegiser) do
    events:UnRegisterEvent(k, v)
  end
end

function events:startRecording_Events()
  for k, v in pairs(_recordingEvents) do
    events:RegisterEvent(k, v)
  end
end

function events:stopRecording_Events()
  for k, v in pairs(_recordingEvents) do
    events:UnregisterEvent(k, v)
  end
end

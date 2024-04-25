local addonName = ... ---@type string

---@class Addon: AceMessage
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class ShortyUtil: AceModule
local ShortyUtil = addon:GetModule("ShortyUtil")

---@class Database: AceModule
local db = addon:GetModule("Database")

---@class Events: AceEvent
local events = addon:NewModule("Events")


local _autoRecordEvents = {
  ["PLAYER_ENTERING_WORLD"] = "EnterWorld", -- This is the event we want to watch if autoRecord is true
  ["PLAYER_LEAVING_WORLD"] = "LeaveWorld"   -- This might be the better event to stop recording when autoRecord is true
}

local _recordingEvents = {
  ["LOOT_READY"] = function () addon:SendMessage("recording/lootReady") end,
  ["LOOT_OPENED"] = function () addon:SendMessage("recording/lootOpened") end,
  ["LOOT_SLOT_CHANGED"] =
  -- Sends a message to notify that the loot slot has changed.
  ---@param _ ignored - The first parameter (ignored).
  ---@param slot number The index of the updated loot slot.
  ---@param ... any The rest of the parameters.
      function (_, slot, ...)
        addon:SendMessage("recording/lootSlotChanged", slot, ...)
      end,
  ["LOOT_SLOT_CLEARED"] =
  ---Sends a message indicating that a loot slot has been cleared.
  ---@param _ ignored - The first parameter (ignored).
  ---@param lootSlot number - The loot slot that has been cleared.
      function (_, lootSlot)
        addon:SendMessage("recording/lootSlotCleared", lootSlot)
      end
}

LibStub("AceEvent-3.0"):Embed(events)

function events:OnInitialize()
  -- Register events to listen for
  -- for k, v in pairs(_autoRecordEvents) do
  --   events:RegisterEvent(k, v)
  -- end
end

function events:EnterWorld(_, initialLogin, reload, ...)
  local _x = ...
  local _inInstance, _instanceType = IsInInstance()

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
  for k, v in pairs(_autoRecordEvents) do
    events:UnregisterEvent(k, v)
  end
end

function events:startRecording_Events()
  --addon:Print("Listening to events")
  for k, v in pairs(_recordingEvents) do
    events:RegisterEvent(k, v)
  end
end

function events:stopRecording_Events()
  --addon:Print("Stopping listening to events")
  for k, v in pairs(_recordingEvents) do
    events:UnregisterEvent(k, v)
  end
end

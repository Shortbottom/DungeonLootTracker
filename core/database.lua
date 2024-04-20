local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class Database: AceModule
local DB = addon:NewModule("Database")

function DB:OnInitialize()
  DB.data = LibStub("AceDB-3.0"):New("dltDB", constants.DATABASE_DEFAULTS)
end

function DB:GetData()
  return DB.data
end

---Get the value of AutoRecord
---@return boolean
function DB:GetAutoRecord()
  return DB.data.profile.recording.autoRecord
end

---Set if AutoRecord is enabled/disabled
---@param enabled boolean
function DB:SetAutoRecord(enabled)
  DB.data.profile.recording.autoRecord = enabled
end

---Get the value of addon:PrintMoneyEarned
---@return boolean
function DB:GetPrintMoneyEarned()
  return DB.data.profile.recording.PrintMoneyEarned
end

---Set if addon:PrintMoneyEarned is enabled/disabled
---@param enabled boolean
function DB:SetPrintMoneyEarned(enabled)
  if enabled then
    DB.data.profile.recording.printMoneyEarned = true
  else
    DB.data.profile.recording.printMoneyEarned = false
  end
end

---Get the value of Minimap Locked
---@return boolean
function DB:GetMinimapLock()
  return DB.data.profile.minimap.lock
end

---Set if Minimap Locked is enabled/disabled
---@param enabled boolean
function DB:SetMinimapLock(enabled)
  DB.data.profile.minimap.lock = enabled
end

---Get the value of Show Minimap. True is false and false is true
---@return boolean
function DB:GetMinimapHide()
  return DB.data.profile.minimap.hide
end

---Hide the Minimap button
---@param enabled boolean
function DB:SetMinimapHide(enabled)
  DB.data.profile.minimap.hide = enabled
end

---Get the position of the button on the minimap
---@return number # number as degrees from 0 to 360
function DB:GetMinimapPos()
  return DB.data.profile.minimap.minimapPos
end

---Set the position of the button on the minimap
---@param value number number as degrees from 0 to 360
function DB:SetMinimapPos(value)
  DB.data.profile.minimap.minimapPos = value
end

DB:Enable()

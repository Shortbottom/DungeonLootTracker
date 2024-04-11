local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class RecordsDB: AceModule
local recordsDB = addon:NewModule("RecordsDB")

function recordsDB:OnInitialize()

end

function recordsDB:NewRecording(arg)
  print("Making a new recording")
end

function recordsDB:GetNewID()
  return random(1, 999999999)
end

recordsDB:Enable()

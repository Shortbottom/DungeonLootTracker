-- This contains all the functions for the Options-Recording section
local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class RecordingOpts: AceModule
local recordingOpts = addon:NewModule("RecordingOpts")

---@type AceConfig.OptionsTable
local options = {
  name = "Recording",
  handler = addon,
  type = "group",
  order = 1,
  args = {
    autoRecord = {
      type = "toggle",
      name = "Auto Record",
      desc = "Do you want to start recording as soon as you enter an instance without being asked?",
      get = function () return DB:GetAutoRecord() end,
      set = function (_, val) DB:SetAutoRecord(val) end
    },
    printMoneyEarned = {
      type = "toggle",
      name = "Print Total Earned",
      desc = "Do you want to print the amount of gold earned during recording to the chat frame at the end of a recording?",
      get = function () return DB:GetPrintMoneyEarned() end,
      set = function (_, val) DB:SetPrintMoneyEarned(val) end
    }
  }
}

function recordingOpts:OnInitialize()

end

function recordingOpts:GetRecordingOptions()
  return options
end

recordingOpts:Enable()

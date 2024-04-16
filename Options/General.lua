local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class GeneralOptions: AceModule
local genOpts = addon:NewModule("GeneralOptions")

---@type AceConfig.OptionsTable
local options = {
  name = "General",
  handler = addon,
  type = "group",
  order = 1,
  args = {
    placeHolder = {
      type = "toggle",
      name = "Placeholder",
      desc = "Placeholder",
      --get = "func() return call a function here end",
      --set = "function (_, val) DB:SetAutoRecord(val) end"
    }
  }
}

function genOpts:GetGeneralOptions()
  return options
end

genOpts:Enable()

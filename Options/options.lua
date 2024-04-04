local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Localisation: AceModule
local L = addon:GetModule("Localisation")

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class Options: AceModule
local options = addon:NewModule("Options")

---@class Events: AceModule
local events = addon:GetModule("Events")

local GUI = LibStub("AceGUI-3.0")

---@return AceConfig.OptionsTable
function config:GetGeneralOptions()
  ---@type AceConfig.OptionsTable
  local options = {}
  return options
end

---@return AceConfig.OptionsTable
function options:GetOptions()
  ---@type AceConfig.OptionsTable
  local options = {
    type = "group",
    name = L:G(addon.Metadata.Title),
    args = {
      general = self:GetGeneralOptions()
    }
  }
end

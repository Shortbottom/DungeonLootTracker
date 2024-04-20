local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Localisation: AceModule
local L = addon:GetModule("Localisation")

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class ShortyUtil: AceModule
local util = addon:GetModule("ShortyUtil")

---@class Events: AceModule
local events = addon:GetModule("Events")

---@class GeneralOptions: AceModule
local generalOptions = addon:GetModule("GeneralOptions")

---@class RecordingOpts: AceModule
local recordingOpts = addon:GetModule("RecordingOpts")

---@class MinimapOptions: AceModule
local minimapOptions = addon:GetModule("MinimapOptions")

---@class Options: AceModule
local options = addon:NewModule("Options")

function options:GetInfoOptions()
  local opt = {
    type = "group",
    name = "About this AddOn",
    order = 5,
    args = {
      Author = {
        type = "description",
        width = "full",
        fontSize = "medium",
        order = 0,
        name = "Author: " .. addon.Metadata.Author, --:SetColorAllianceBlue() .. addon.Authors
        desc = "The names of the authors"
      },
      Version = {
        type = "description",
        width = "full",
        fontSize = "medium",
        order = 1,
        name = "Version: " .. addon.Metadata.Version, --:SetColorAllianceBlue() .. addon.Version
        desc = "The version of the addon"
      }
    }
  }
  return opt
end

function options:GetOptions()
  local opt = {
    type = "group",
    name = L["AddonName"],
    args = {
      general = generalOptions:GetGeneralOptions(),
      recording = recordingOpts:GetRecordingOptions(),
      minimap = minimapOptions:GetMinimapOptions(),
      info = self:GetInfoOptions()
    }
  }
  return opt
end

function options:OnEnable()
  LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, function () return self:GetOptions() end)
  self.frame, self.category = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, addon.Metadata.Title)
  LibStub("AceConfigDialog-3.0"):SetDefaultSize(addonName, 500, 500)
end

options:Enable()

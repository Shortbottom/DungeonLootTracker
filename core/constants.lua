---@diagnostic disable: duplicate-set-field,duplicate-doc-field,duplicate-doc-alias
local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Localisation: AceModule
local L = addon:GetModule("Localisation")

---@class Constants: AceModule
local const = addon:NewModule("Constants")

addon.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
addon.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
addon.isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
addon.isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

---@type string Name of the main category in the blizzard add on options
addon.optionsCategoryName = "DungeonLootTracker_options"

---@class databaseOptions
---@field profile table
---@field general: profile
const.DATABASE_DEFAULTS = {
  profile = {
    general = {
      enabled = true,    -- INFO: We of course want our AddOn to be enabled by default
      autoRecord = false -- INFO: We don't want the AddOn to automatically do something unless the User has chosen for it to
    },
    minimap = {
      hide = false,             -- INFO: Show the minimap button by default
      lock = false,             -- INFO: Don't lock the position of the minimap button
      minimapPos = 90,          -- INFO: Position of the button on the minimap
      showInCompartment = false -- INFO: Show in the new addon compartment
    }
  },
  char = {}
}


---@type string Name of the minimap button
const.miniMapBtnName = addon.Metadata.Acronym .. "_MinimapBtn"

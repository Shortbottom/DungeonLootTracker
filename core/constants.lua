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

if not addon.isRetail then
  Enum.ItemQuality.Poor = 0
  Enum.ItemQuality.Common = 1
  Enum.ItemQuality.Uncommon = 2
  Enum.ItemQuality.Rare = 3
  Enum.ItemQuality.Epic = 4
  Enum.ItemQuality.Legendary = 5
  Enum.ItemQuality.Artifact = 6
  Enum.ItemQuality.Heirloom = 7
  Enum.ItemQuality.WoWToken = 8
end

const.ITEM_QUALITY_COLOR = {
  [Enum.ItemQuality.Poor] = { 0.62, 0.62, 0.62, 1 },
  [Enum.ItemQuality.Common] = { 1, 1, 1, 1 },
  [Enum.ItemQuality.Uncommon] = { 0.12, 1, 0, 1 },
  [Enum.ItemQuality.Rare] = { 0.00, 0.44, 0.87, 1 },
  [Enum.ItemQuality.Epic] = { 0.64, 0.21, 0.93, 1 },
  [Enum.ItemQuality.Legendary] = { 1, 0.50, 0, 1 },
  [Enum.ItemQuality.Artifact] = { 0.90, 0.80, 0.50, 1 },
  [Enum.ItemQuality.Heirloom] = { 0, 0.8, 1, 1 },
  [Enum.ItemQuality.WoWToken] = { 0, 0.8, 1, 1 }
}

---@type string Name of the minimap button
const.miniMapBtnName = addon.Metadata.Acronym .. "_MinimapBtn"

---@class RecordList
---@field recordID number A uniqueID for this recording to make it easier to select later - Will be used for deleting etc
---@field instanceID number An ID for zone/instance the player was in when recording started.
---@field startTime string The time the recording started UNIX time
---@field endTime string The time the recording ended UNIX time
---@field timeDiff number The length of time from start to end. Holding this here for later so we don't have to do it when we want to use it
---@field goldLooted number The amount of gold looted
---@field items: ItemList
--- INFO: InstanceID This will either be the instanceID of a dungeon or the ID of the zone in the outside world.<br>
--- INFO: Using IDs rather than names so things stored in the SVs can be region agnostic
--- INFO: All times will be held as a unix time offset by the server's time zone (e.g. UTC minus 5 hours).
const.RECORD_LIST_DEFAULTS = {
  recordID = 0,
  instanceID = "",
  startTime = 0,
  endTime = 0,
  recordTimeDiff = 0,
  goldLooted = 0,
  items = { const.RECORD_ITEM_DEFAULTS }
}

---@class ItemList
---@field itemID number ItemID of the item. Should be the blizzard provided one
---@field displayID number Might need this to know what Icon to show otherwise get rid of it
---@field qualityColorID number Item Quality.
---@field qty number Amount of this item that has been picked up. Will be 1 for things like weapons/armor but for tradeskill items like cloth etc it can be more.
---@field value number The value of this item.
---@field Keep boolean If we should keep this item when vendoring.
--- ?: [value] Not sure where to get this from.<br>
--- ?: [Keep]: When do I set this flag? If I set it on pickup then if the player changes their settings after a recording then<br>this should use the old setting if they then use this AddOn to vendor items from the recording.<br>
--- TODO: [value] Possibly build in support for AH AddOn values
const.RECORD_ITEM_DEFAULTS = {
  itemID = 0,
  displayID = 0,
  qualityColorID = 0,
  qty = 0,
  value = 0,
  Keep = true,
}

---@diagnostic disable: duplicate-set-field,duplicate-doc-field,duplicate-doc-alias
local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Localisation: AceModule
local L = addon:GetModule("Localisation")

---@class Constants: AceModule
local const = addon:NewModule("Constants")

addon.isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
addon.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
addon.isBCC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
addon.isWrath = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC

addon.currentRecID = 0

---@type string Name of the main category in the blizzard add on options
addon.optionsCategoryName = "DungeonLootTracker_options"

const.DATABASE_DEFAULTS = {
  profile = {
    general = {
      enabled = true -- INFO: We of course want our AddOn to be enabled by default
    },
    recording = {
      autoRecord = false,      -- We don't want the AddOn to automatically do something unless the User has chosen for it to
      printMoneyEarned = false -- Default should be not to addon:Print the amount of gold earned during a recording
    },
    minimap = {
      hide = false,             -- Show the minimap button by default
      lock = false,             -- Don't lock the position of the minimap button
      minimapPos = 90,          -- Position of the button on the minimap
      showInCompartment = false -- Show in the new addon compartment
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

---@enum LootSlotType
const.LootSlotType = {
  None = 0,
  Item = 1,
  Money = 2,
  Currency = 3
}

---@type string Name of the minimap button
const.miniMapBtnName = addon.Metadata.Acronym .. "_MinimapBtn"

--- INFO: InstanceID This will either be the instanceID of a dungeon or the ID of the zone in the outside world.<br>
--- INFO: Using IDs rather than names so things stored in the SVs can be region agnostic<br>
--- INFO: All times will be held as a unix time offset by the server's time zone (e.g. UTC minus 5 hours).
const.RECORD_LIST_DEFAULTS = {
  recordID = 0,
  instanceID = "",
  isInstance = false,
  startTime = 0,
  endTime = 0,
  timeDiff = 0,
  playerMoneyStart = 0,
  playerMoneyEnd = 0,
  playerMoneyDiff = 0,
  goldLooted = 0,
  items = { const.RECORD_ITEM_DEFAULTS }
}

--- ?: [value] Not sure where to get this from.<br>
--- ?: [Keep]: When do I set this flag? If I set it on pickup then if the player changes their settings after a recording then<br>this should use the old setting if they then use this AddOn to vendor items from the recording.<br>
--- TODO: [value] Possibly build in support for AH AddOn values

---This table contains the default values for recording an item.
---Each key represents a specific property of the item.
---The values are initialized to their default values.
---@class ItemList
const.RECORD_ITEM_DEFAULTS = {
  slotType = 0,
  itemID = 0,
  itemName = "",
  icon = 0,
  quality = 0,
  quantity = 0,
  value = 0,
  keep = true,
  looted = false,
  currencyID = 0,
  locked = false,
  isQuestItem = false,
  questID = 0,
  isActive = false,
  classID = 0,
  subClassID = 0,
  itemLink = ""
}

local addonName = ... ---@type string

---@class Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Metadata: AceModule
local metadata = addon:NewModule("Metadata")

---Get all the Metadata and store it locally in our Addon Namespace
---@param name string The Addon name as wow sees it
---@return table Return a table containing all the Metadata
function metadata:GetAddOnMetadata(name)
  local version = C_AddOns.GetAddOnMetadata(name, "Version")
  local title = C_AddOns.GetAddOnMetadata(name, "Title")       --name -- Name of the AddOn folder
  local acronym = C_AddOns.GetAddOnMetadata(name, "X-Acronym") -- Short abbreviation for the addonName
  local notes = C_AddOns.GetAddOnMetadata(name, "Notes")
  local icon = C_AddOns.GetAddOnMetadata(name, "IconTexture")  --"Interface\\Addons\\DungeonLootTracker\\Images\\icon"
  local author = C_AddOns.GetAddOnMetadata(name, "Author")
  local wago = C_AddOns.GetAddOnMetadata(name, "X-Wago-ID")
  local curse = C_AddOns.GetAddOnMetadata(name, "X-Curse-Project-ID")
  local build = ""
  return {
    AddonName = addonName,
    Title = title,
    Version = version,
    Build = build,
    Acronym = acronym,
    Notes = notes,
    Icon = icon,
    Author = author,
    WAGO = wago,
    Curse = curse
  }
end

addon.Metadata = metadata:GetAddOnMetadata(addonName)

metadata:Enable()

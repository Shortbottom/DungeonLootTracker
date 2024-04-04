local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Metadata: AceModule
local metadata = addon:NewModule("Metadata")

---Get all the Metadata and store it locally in our Addon Namespace
---@param addonName string The Addon name as wow sees it
---@return table Return a table containing all the Metadata
function metadata:GetAddOnMetadata(addonName)
  local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
  local title = C_AddOns.GetAddOnMetadata(addonName, "Title")       --addonName -- Name of the AddOn folder
  local acronym = C_AddOns.GetAddOnMetadata(addonName, "X-Acronym") -- Short abbreviation for the addonName
  local notes = C_AddOns.GetAddOnMetadata(addonName, "Notes")
  local icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture")  --"Interface\\Addons\\DungeonLootTracker\\Images\\icon"
  local author = C_AddOns.GetAddOnMetadata(addonName, "Author")
  local wago = C_AddOns.GetAddOnMetadata(addonName, "X-Wago-ID")
  local curse = C_AddOns.GetAddOnMetadata(addonName, "X-Curse-Project-ID")

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

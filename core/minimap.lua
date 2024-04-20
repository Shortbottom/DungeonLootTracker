local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local const = addon:GetModule("Constants")

---@class MainFrame: AceModule
local mainFrame = addon:GetModule("MainFrame")

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class Minimap: AceModule
local minimap = addon:NewModule("Minimap")

---@class Icon: LibDBIcon
addon.minimapIcon = LibStub("LibDBIcon-1.0")

--- Setup the LDB Data Object for the minimap icon
---@type table
local dltLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addon.Metadata.AddonName, {
  type = "data source",
  text = "Dungeon Loot Tracker",
  icon = addon.Metadata.Icon,
  OnClick = function (_, button)
    minimap:minimap_Click(button)
  end
})

function minimap:OnInitialize()
  -- Load the Minimap Button
  addon.minimapIcon:Register(const.miniMapBtnName, dltLDB, DB:GetData().profile.minimap)
end

---Event Handler: MouseClick on the minimap button. Left/Right clicks do different things
---@param button string This is the name of the button that generated the click event in string format - <Any(Up/Down)> <LeftButton(Up/Down) <RightButton(Up/Down)>
function minimap:minimap_Click(button)
  if button == "LeftButton" then
    mainFrame:toggleFrame()
  elseif button == "RightButton" then
    minimap:openOptions()
  end
end

---Open the options window
function minimap:openOptions()
  LibStub("AceConfigDialog-3.0"):Open(addonName)
end

minimap:Enable()

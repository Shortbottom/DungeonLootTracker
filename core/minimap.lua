local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local const = addon:GetModule("Constants")

---@class MainFrame: AceModule
local mainFrame = addon:GetModule("MainFrame")

---@class Icon: AceAddon
local icon = LibStub("LibDBIcon-1.0")

---@class Minimap: AceModule
local minimap = addon:NewModule("Minimap")

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
  minimap:LoadMinimapBtn()
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
  if addon.IsWrathClassic then
    InterfaceAddOnsList_Update() -- This way the correct category will be shown when calling InterfaceOptionsFrame_OpenToCategory
    InterfaceOptionsFrame_OpenToCategory(self)
    for _, btn in next, InterfaceOptionsFrameAddOns.buttons do
      if btn.element and btn.element.name == self and btn.element.collapsed then
        OptionsListButtonToggle_OnClick(btn.toggle)
        break
      end
    end
    return
  end
  _G["Settings"].GetCategory(addon.optionsCategoryName).expanded = true
  _G["Settings"].OpenToCategory(addon.optionsCategoryName, true)
end

function minimap:LoadMinimapBtn()
  icon:Register(addon.Metadata.Acronym .. "_MinimapBtn", dltLDB, addon.db.profile.minimap)
end

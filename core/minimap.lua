local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local const = addon:GetModule("Constants")

---@class MainFrame: AceModule
local mainFrame = addon:GetModule("MainFrame")

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class Minimap: AceModule
local minimap = addon:NewModule("Minimap")

---@class Icon: AceAddon
local icon = LibStub("LibDBIcon-1.0")

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
  icon:Register(const.miniMapBtnName, dltLDB, DB:GetData().profile.minimap)
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

---Lock the minimap button
function minimap:Lock()
  icon:Lock(const.miniMapBtnName)
end

---Unlock the minimap button
function minimap:Unlock()
  icon:Unlock(const.miniMapBtnName)
end

---Show the minimap button
function minimap:Show()
  icon:Show(const.miniMapBtnName)
end

---Hide the minimap button
function minimap:Hide()
  icon:Hide(const.miniMapBtnName)
end

function minimap:SetPosition(arg)
  icon:Refresh(const.miniMapBtnName, DB:GetData().profile.minimap)
end

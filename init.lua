---@diagnostic disable: duplicate-set-field,duplicate-doc-field,duplicate-doc-alias
local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Localisation: AceModule
local L = addon:GetModule("Localisation")

---@class Metadata: AceModule
local metadata = addon:GetModule("Metadata")

---@class Database: AceModule
local database = addon:GetModule("Database")

---@class RecordsDB: AceModule
local rDB = addon:GetModule("RecordsDB")

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class Events: AceModule
local events = addon:GetModule("Events")

---@class MainFrame: AceModule
local mainFrame = addon:GetModule("MainFrame")

---@class Minimap: AceModule
local minimap = addon:GetModule("Minimap")

---@class Options: AceModule
local options = addon:GetModule("Options")

---@class Recording: AceModule
local recording = addon:GetModule("Recording")

local _slashCmds = { "dlt", "dungeonloottracker" }

-- TODO Will need this later when we put Archivist in
-- ---@class Archivist: AceModule
-- local dlt_archivist = addon:GetModule("DLT_Archivist")

function addon:OnInitialize()
  LibStub("AceEvent-3.0"):Embed(addon)
end

function addon:OnEnable()
  -- Code that runs when the AddOn is enabled
  metadata:Enable()
  mainFrame:Enable()
  minimap:Enable()
  recording:Enable()
  -- dlt_archivist:Enable() -- TODO Saving for later

  for _, v in pairs(_slashCmds) do
    addon:RegisterChatCommand(v, "slashCommand")
  end
end

function addon:OnDisable()
  -- Code that runs when the AddOn is disabled
  metadata:Disable()
  mainFrame:Disable()
  minimap:Disable()
  recording:Disable()
  addon:Disable()
end

---Event handle for slashCommand
---@param self self
---@param msg string
function addon:slashCommand(msg)
  if not msg or strtrim(msg) == "" then
    -- If no args are passed in the slash command we just want to toggle the window being shown
    ShortyUtil:toggleWindow("DLT_Parent_")
  elseif msg == "options" then
    addon:openOptions()
  elseif msg == "help" then
    local helpMsg = "Dungeon Loot Tracker Commands"
    helpMsg = helpMsg .. "\n /dlt -- will toggle the window being shown."
    helpMsg = helpMsg .. "\n /dlt options -- opens the AddOn options in the blizzard options window"
    helpMsg = helpMsg .. "\n /dlt help -- shows this help message."
    addon:Print(helpMsg)
    --@do-not-package@
    -- ! WE DO NOT WANT THIS MAKING IT INTO THE RELEASE VERSION AS SOMEONE IS BOUND TO "ACCIDENTALLY" USE IT
  elseif msg == "wipe" then
    addon:Print("wiping all data")
    rDB.data.records = {}
    rDB.data.lastUsedID = 0
    rDB.data.totalRecordings = 0
    --@end-do-not-package@  else
  end
end

---Open the options window
function addon:openOptions()
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

  Settings.GetCategory(addon.optionsFrame.name).expanded = true
  Settings.OpenToCategory(addon.optionsFrame.name, true)
end

---RefreshConfig
function addon.RefreshConfig()
  AceConfigRegistry:NotifyChange(addon.Metadata.AddonName)
end

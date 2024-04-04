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

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class Events: AceModule
local events = addon:GetModule("Events")

---@class MainFrame: AceModule
local mainFrame = addon:GetModule("MainFrame")

---@class Minimap: AceModule
local minimap = addon:GetModule("Minimap")

--[[
-- TODO: We should do the localisation here
-- TODO: Localisation End

local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDB = LibStub("AceDB-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")
local icon = LibStub("LibDBIcon-1.0")
local ShortyUtil = LibStub("Shorty_Util")

---@class Metadata
DLT_Addon.Metadata = ShortyUtil.Metadata.GetAddOnMetadata(addonName)

DLT_Addon.MinimapBtnName = DLT_Addon.Metadata.AddonName .. "_Minimap"

-- TODO: Set the defaults to use the
local defaults = {
  profile = {
    general = {
      autoRecord = false -- INFO: We don't want the AddOn to automatically do something unless the User has chosen for it to
    },
    minimap = {
      hide = false,
      lock = false,
      minimapPos = 90,
      showInCompartment = false
    }
  },
}

-- Setup all the Tables for the options windows
-- TODO: Set the color for author and version etc to the faction of the character

local mainSettingsInfo = {
  name = DLT_Addon.Metadata.Title,
  handler = DLT_Addon,
  type = "group",
  args = {
    info = {
      type = "header",
      name = "",
      desc = "Name of the Add On"
    }
  }
}

local generalOptions = {
  name = DLT_Addon.Metadata.Title .. ": General",
  handler = DLT_Addon,
  type = "group",
  args = {
    info = {
      type = "header",
      name = "",
      desc = ""
    },
    autoRecord = {
      type = "toggle",
      name = "Auto Record",
      desc = "Do you want to start recording as soon as you enter an instance without being asked?",
      get = "getAutoRecord",
      set = "setAutoRecord"
    }
  }
}

local minimapOptions = {
  name = DLT_Addon.Metadata.Title .. ": Minimap",
  handler = DLT_Addon,
  type = "group",
  args = {
    info = {
      type = "header",
      name = "",
      desc = ""
    },
    showMinimapBtn = {
      type = "toggle",
      name = "Show Minimap Button",
      desc = "Show/Hide the Minimap Button.",
      get = function () DLT_Addon:GetShowMinimap() end,
      set = function () DLT_Addon:SetShowMinimap() end
    },
    lockMinimapBtn = {
      type = "toggle",
      name = "Lock Minimap Button",
      desc = "Lock the position of the minimap button.",
      get = function (_)
        return DLT_Addon.db.profile.minimap.lock
      end,
      set = "setLockMinimap"
    }
  }
}
--]]

--- Setup the LDB Data Object for the minimap icon
---@type table
local dltLDB =
    LibStub("LibDataBroker-1.1"):NewDataObject(
      addon.Metadata.AddonName,
      {
        type = "data source",
        text = "Dungeon Loot Tracker",
        icon = addon.Metadata.Icon,
        OnClick = function (_, button)
          minimap:minimap_Click(button)
        end
      }
    )

function addon:OnInitialize()
  print("test")
  --[[

  -- NOTE: We want this loaded first so that we make sure that when things load they are set correctly
  -- Load the SavedVariables
  self.db = LibStub("AceDB-3.0"):New("dltDB", defaults)
  self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
  self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
  ------------------ Setup the options and add it to the Blizzard AddOn options frame ------------------

  -- First Page should be an info page - Should contain Authors name and appreciation for particular people etc
  AceConfig:RegisterOptionsTable("DungeonLootTracker_options", mainSettingsInfo)
  DLT_Addon.optionsFrame = AceConfigDialog:AddToBlizOptions("DungeonLootTracker_options", DLT_Addon.Metadata.Title)

  -- Add the General Tab
  AceConfig:RegisterOptionsTable("DungeonLootTracker_General", generalOptions)
  AceConfigDialog:AddToBlizOptions("DungeonLootTracker_General", "General", DLT_Addon.Metadata.Title)

  -- Add the Minimap Tab
  AceConfig:RegisterOptionsTable("DungeonLootTracker_Minimap", minimapOptions)
  AceConfigDialog:AddToBlizOptions("DungeonLootTracker_Minimap", "Minimap", DLT_Addon.Metadata.Title)

  -- Add the use of profiles
  local profiles = AceDBOptions:GetOptionsTable(self.db)
  AceConfig:RegisterOptionsTable("DungeonLootTracker_Profiles", profiles)
  AceConfigDialog:AddToBlizOptions("DungeonLootTracker_Profiles", "Profiles", DLT_Addon.Metadata.Title)

  -- Register Chat Commands
  self:RegisterChatCommand("dlt", "slashCommand")
  self:RegisterChatCommand(DLT_Addon.Metadata.AddonName, "slashCommand")

  -- NOTE: Doesn't really matter but set the default to be not recording;
  -- NOTE: This is just to ensure that the key is set to a value and isn't left as null
  local f = _G["DLT_Parent_ToggleRecordingBtn"]
  f.recording = false

  ]]
end

function addon:OnEnable()
  -- Code that runs when the AddOn is enabled
  metadata:Enable()
  mainFrame:Enable()
  minimap:Enable()
end

function addon.OnDisable()
  -- Code that runs when the AddOn is disabled
  DLT_Addon:Disable()
end

---Event handle for slashCommand
---@param self self
---@param msg string
function addon:slashCommand(msg)
  if not msg or strtrim(msg) == "" then
    -- If no args are passed in the slash command we just want to toggle the window being shown
    ShortyUtil:toggleWindow("DLT_Parent_")
  elseif msg == "options" then
    DLT_Addon:openOptions()
  elseif msg == "help" then
    local helpMsg = "Dungeon Loot Tracker Commands"
    helpMsg = helpMsg .. "\n /dlt -- will toggle the window being shown."
    helpMsg = helpMsg .. "\n /dlt options -- opens the AddOn options in the blizzard options window"
    helpMsg = helpMsg .. "\n /dlt help -- shows this help message."
    self:Print(helpMsg)
  else
    self:Print(msg)
  end
end

--[[

---Event Handler: MouseClick on the minimap button. Left/Right clicks do different things
---@param self string This is self, we don't need it so ignore it
---@param button string This is the name of the button that generated the click event in string format - <Any(Up/Down)> <LeftButton(Up/Down) <RightButton(Up/Down)>
function addon.minimap_Click(self, button)
  if button == "LeftButton" then
    ShortyUtil:toggleWindow("DLT_Parent_")
  elseif button == "RightButton" then
    DLT_Addon:openOptions()
  end
end
]]

---Open the options window
function addon:openOptions()
  if DLT_Addon.IsWrathClassic then
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

  Settings.GetCategory(DLT_Addon.optionsFrame.name).expanded = true
  Settings.OpenToCategory(DLT_Addon.optionsFrame.name, true)
end

---Gets the value of the Auto Record setting from the characters SavedVariables
---@return boolean
function addon:getAutoRecord()
  return DLT_Addon.db.profile.general.autoRecord
end

---Save the Auto Record setting
---@param value boolean # If the user has chosen to auto record or not
function addon:setAutoRecord(_, value)
  self.db.profile.general.autoRecord = value
end

---RefreshConfig
function addon.RefreshConfig()
  AceConfigRegistry:NotifyChange(DLT_Addon.Metadata.AddonName)
end

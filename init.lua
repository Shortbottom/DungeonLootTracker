-- INFO: addonName is the name of the AddOn folder; in this case DungeonLootTracker
-- INFO: addon is the name of a Table that is shared for all files in this addon - can hole simple variables or functions
local addonName, addon = ...

-- TODO: We should do the localisation here
-- TODO: Localisation End

addon = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "Shorty_Util")
AceConfig = LibStub("AceConfig-3.0")
AceConfigDialog = LibStub("AceConfigDialog-3.0")
AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
AceDBOpt = LibStub("AceDBOptions-3.0")

local icon = LibStub("LibDBIcon-1.0")

addon.VersionNum = C_AddOns.GetAddOnMetadata(addonName, "Version")
addon.Version = "v" .. addon.VersionNum
addon.Build = GetBuildInfo()
addon.BuildVersion = addon.Build .. "." .. addon.VersionNum
addon.Title = C_AddOns.GetAddOnMetadata(addonName, "Title")       --addonName -- Name of the AddOn folder
addon.Acronym = C_AddOns.GetAddOnMetadata(addonName, "X-Acronym") -- Short abbreviation for the addonName
addon.Notes = C_AddOns.GetAddOnMetadata(addonName, "Notes")
addon.Icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture")  --"Interface\\Addons\\DungeonLootTracker\\Images\\icon"
addon.Authors = C_AddOns.GetAddOnMetadata(addonName, "Author")

-- Setup all the Tables for the options windows
-- TODO: Set the color for author and version etc to the faction of the currently logged in player
local generalOptions = {
    type = "group",
    name = addon.Title,
    handler = addon,
    args = {
        Header = {
            type = "header",
            name = "",
            desc = "Name of the Add On"
        },
        Info = {
            type = "group",
            inline = true,
            name = "About this AddOn",
            args = {
                Author = {
                    type = "description",
                    width = 50,
                    fontSize = "medium",
                    name = ("Author: "):SetColorAllianceBlue() .. addon.Authors
                },
                Version = {
                    type = "description",
                    width = 200,
                    fontSize = "medium",
                    name = ("Version: "):SetColorAllianceBlue() .. addon.Version
                }

            }
        }
    },
}

local recordingOptions = {
    type = "group",
    name = "Recording Options",
    handler = addon,
    args = {
        Info = {
            type = "header",
            name = "",
            desc = "Name of the Add On"
        },
        autoRecord = {
            type = "toggle",
            name = "Auto Record",
            desc = "Do you want to start recording as soon as you enter an instance without being asked?",
        }
    },
}


local minimapOptions = {
    name = addon.Title .. ": Minimap",
    handler = addon,
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
            get = function(info) return not addon.db.profile.minimap.hide end,
            set = "setShowMinimap"
        },
        lockMinimapBtn = {
            type = "toggle",
            name = "Lock Minimap Button",
            desc = "Lock the position of the minimap button.",
            get = function(_) return addon.db.profile.minimap.lock end,
            set = "setLockMinimap"
        }

    }
}

-- Setup the LDB Data Object for the minimap icon
local dltLDB = LibStub("LibDataBroker-1.1"):NewDataObject(addonName, {
    type    = "data source",
    text    = "Dungeon Loot Tracker",
    icon    = addon.Icon,
    OnClick = function(self, button)
        addon:minimap_Click(addon.Title, button)
    end,
})


function addon:OnInitialize()
    -- NOTE: We want this loaded first so that we make sure that when things load they are set correctly
    -- Load the SavedVariables
    self.db = LibStub("AceDB-3.0"):New("dltDB", defaults, profile)

    AceConfig:RegisterOptionsTable(addon.Title, generalOptions)
    local _, catID = AceConfigDialog:AddToBlizOptions(addon.Title, addon.Title, nil)

    AceConfig:RegisterOptionsTable(addon.Acronym .. "_Recording", recordingOptions)
    AceConfigDialog:AddToBlizOptions(addon.Acronym .. "_Recording", "Recording Options", addon.Title)

    AceConfig:RegisterOptionsTable(addon.Acronym .. "_Minimap", minimapOptions)
    AceConfigDialog:AddToBlizOptions(addon.Acronym .. "_Minimap", "Minimap Options", addon.Title)

    -- Add the use of profiles
    local profiles = AceDBOpt:GetOptionsTable(self.db)
    AceConfig:RegisterOptionsTable(addon.Acronym .. "_Profiles", profiles)
    AceConfigDialog:AddToBlizOptions(addon.Acronym .. "_Profiles", "Profiles", addon.Title)

    -- Register Chat Commands
    self:RegisterChatCommand("dlt", "slashCommand")
    self:RegisterChatCommand(addonName, "slashCommand")

    -- NOTE: Doesn't really matter but set the default to be not recording;
    -- NOTE: This is just to ensure that the key is set to a value and isn't left as null
    DLT_Parent_ToggleRecordingBtn.recording = false
end

function addon:OnEnable()
    -- Code that runs when the AddOn is enabled
    addon:Enable()

    -- Load the Minimap Button
    icon:Register(addonName .. "_Minimap", dltLDB, self.db.profile.minimap)

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function addon:OnDisable()
    -- Code that runs when the AddOn is disabled
    addon:Disable()
end

function addon:slashCommand(msg)
    if not msg or msg:trim() == "" then
        -- If no args are passed in the slash command we just want to toggle the window being shown
        addon:toggleWindow()
    elseif msg == "options" then
        -- If options are passed as an arg in the slash command we want to open the blizzard options panel
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
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

function addon:minimap_Click(title, button)
    if button == "LeftButton" then
        lib.toggleWindow()
    elseif button == "RightButton" then
        if addon.IsWrathClassic then
            InterfaceAddOnsList_Update(); -- This way the correct category will be shown when calling InterfaceOptionsFrame_OpenToCategory
            InterfaceOptionsFrame_OpenToCategory(title);
            for _, button in next, InterfaceOptionsFrameAddOns.buttons do
                if button.element and button.element.name == title and button.element.collapsed then
                    OptionsListButtonToggle_OnClick(button.toggle);
                    break;
                end
            end
            return;
        end

        Settings.GetCategory(title).expanded = true
        Settings.OpenToCategory(title, true)
    end
end

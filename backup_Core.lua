-- DLTAddOn = LibStub("AceAddon-3.0"):NewAddon("DLTAddOn", "AceConsole-3.0")
-- local AceConfig = LibStub("AceConfig-3.0")
-- local AceConfigDialog = LibStub("AceConfigDialog-3.0")
-- local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
-- local AceDBOpt = LibStub("AceDBOptions-3.0")
-- local icon = LibStub("LibDBIcon-1.0") -- Library for creating a minimap icon

local addonName = ...
local DLTAddOn = _G[addonName]

local DLT_ldb = LibStub("LibDataBroker-1.1"):NewDataObject("DLTAddOn", {
    type    = "data source",
    text    = "Dungeon Loot Tracker",
    icon    = "Interface\\Addons\\DungeonLootTracker\\Images\\icon",
    OnClick = function(self, button) DLTAddOn:minimap_Click(self, button) end,
})
local appName = "Dungeon Loot Tracker"

local defaults = {
    profile = {
        autoRecord = false, -- NOTE: We don't want the AddOn to automatically do something unless the User has chosen for it to
        minimap = {
            hide = false,
            lock = true,
            minimapPos = 0,
            showInCompartment = true
        }
    }
}

local options = {
    name = ""
}

local mainSettingsInfo = {
    name = appName,
    handler = DLTAddOn,
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
    name = appName .. ": General",
    handler = DLTAddOn,
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
        },
    }
}

local minimapOptions = {
    name = appName .. ": Minimap",
    handler = DLTAddOn,
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
            get = function(info) return not DLTAddOn.db.profile.minimap.hide end,
            set = "setShowMinimap"
        },
        lockMinimapBtn = {
            type = "toggle",
            name = "Lock Minimap Button",
            desc = "Lock the position of the minimap button.",
            get = function(info) return DLTAddOn.db.profile.minimap.lock end,
            set = "setLockMinimap"
        }

    }
}

-- AceConfigRegistry:RegisterOptionsTable(appName .. " Options", options, true)

function DLTAddOn:OnInitialize()
    -- Load the SavedVariables
    self.db = LibStub("AceDB-3.0"):New("dltDB", defaults, profile)

    ------------------ Setup the options and add it to the Blizzard AddOn options frame ------------------

    -- First Page should be an info page - Should contain Authors name and appreciation for particular people etc
    AceConfig:RegisterOptionsTable("DungeonLootTracker_options", mainSettingsInfo)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("DungeonLootTracker_options", appName)

    -- INFO: Should contain general options
    -- Add the General Tab
    AceConfig:RegisterOptionsTable("DungeonLootTracker_General", generalOptions)
    AceConfigDialog:AddToBlizOptions("DungeonLootTracker_General", "General", appName)

    -- Add the Minimap Tab
    AceConfig:RegisterOptionsTable("DungeonLootTracker_Minimap", minimapOptions)
    AceConfigDialog:AddToBlizOptions("DungeonLootTracker_Minimap", "Minimap", appName)

    -- Add the use of profiles
    local profiles = AceDBOpt:GetOptionsTable(self.db)
    AceConfig:RegisterOptionsTable("DungeonLootTracker_Profiles", profiles)
    AceConfigDialog:AddToBlizOptions("DungeonLootTracker_Profiles", "Profiles", appName)

    -- Load the Minimap Button
    icon:Register(appName .. "_Minimap", DLT_ldb, self.db.profile.minimap)

    -- Register Chat Commands
    self:RegisterChatCommand("dlt", "slashCommand")
    -- self:RegisterChatCommand("dungeonloottracker", "slashCommand")

    -- INFO: Doesn't really matter but set the default to be not recording;
    -- INFO: This is just to ensure that the key is set to a value and isn't left as null
    DLT_Parent_ToggleRecordingBtn.recording = false
end

function DLTAddOn:OnEnable()
    -- Code that runs when the AddOn is enabled
    DLTAddOn:Enable()
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
end

function DLTAddOn:OnDisable()
    -- Code that runs when the AddOn is disabled
    DLTAddOn:Disable()
end

function DLTAddOn:RefreshConfig()
    AceConfigRegistry:NotifyChange(appName)
end

function DLTAddOn:slashCommand(msg)
    if not msg or msg:trim() == "" then
        -- If no args are passed in the slash command we just want to toggle the window being shown
        DLTAddOn:toggleWindow()
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

function DLTAddOn:toggleWindow()
    if DLT_Parent_:IsShown() == true then
        DLT_Parent_:Hide()
    else
        DLT_Parent_:Show()
    end
end

function DLTAddOn:ResetAllInstances()
    print("Ressetting all instances")
end

function DLTAddOn:ChooseDifficulty()
    local isShown = DLT_Difficulties:IsShown()
    if isShown then
        print("Hiding difficulty")
        DLT_Difficulties:Hide()
    else
        print("Showing difficulty")
        DLT_Difficulties:Show()
    end
end

-- Functions to deal with starting and stopping recordings
function DLTAddOn:ToggleRecording_OnClick(self)
    print(self.recording)
    if (self.recording) then
        DLTAddOn:Record_Stop()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    else
        DLTAddOn:Record_Start()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
end

function DLTAddOn:IsRecording()
    return DLT_Parent_ToggleRecordingBtn.recording
end

function DLTAddOn:Record_Start()
    if (DLT_Parent_ToggleRecordingBtn.recording) then
        return
    end
    DLT_Parent_ToggleRecordingBtn.recording = true
    DLT_Parent_ToggleRecordingBtn:SetNormalTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Stop-Up")
    DLT_Parent_ToggleRecordingBtn:SetPushedTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Stop-Up")
end

function DLTAddOn:Record_Stop()
    if (not DLT_Parent_ToggleRecordingBtn.recording) then
        return
    end
    DLT_Parent_ToggleRecordingBtn.recording = false
    DLT_Parent_ToggleRecordingBtn:SetNormalTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Record-Up")
end

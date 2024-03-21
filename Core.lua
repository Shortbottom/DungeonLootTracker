DLTAddOn = LibStub("AceAddon-3.0"):NewAddon("DLTAddOn", "AceConsole-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDBOpt = LibStub("AceDBOptions-3.0")
local appName = "Dungeon Loot Tracker"
local parentFrame = DLT_Parent_

local instanceTable = {
    InstanceType = "Dungeon",
    Difficulties = {

    },
    difficulty = "Normal",

}

local defaults = {
    profile = {
        autoRecord = false, -- We don't want the AddOn to automatically do something unless the User has chosen for it to
    }
}

-- KEEP FOR POSSIBLE USE LATER
-- Journalator.Archiving.LoadUpTo(earliestTimestamp, function()
--     local lootContainers = CopyTable(Journalator.Archiving.GetRange(earliestTimestamp, "LootContainers")
-- end)

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
            set = "setAutoRecord",
        }
    }
}

-- AceConfigRegistry:RegisterOptionsTable(appName .. " Options", options, true)

function DLTAddOn:OnInitialize()
    -- Load the SavedVariables
    self.db = LibStub("AceDB-3.0"):New("dltDB", defaults, profile)
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")

    ------------------ Setup the options and add it to the Blizzard AddOn options frame ------------------

    -- First Page should be an info page
    AceConfig:RegisterOptionsTable("DungeonLootTracker_options", mainSettingsInfo)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions("DungeonLootTracker_options", appName)

    -- Add the General Tab
    AceConfig:RegisterOptionsTable("DungeonLootTracker_General", generalOptions)
    AceConfigDialog:AddToBlizOptions("DungeonLootTracker_General", "General", appName)

    -- Add the use of profiles
    local profiles = AceDBOpt:GetOptionsTable(self.db)
    AceConfig:RegisterOptionsTable("DungeonLootTracker_Profiles", profiles)
    AceConfigDialog:AddToBlizOptions("DungeonLootTracker_Profiles", "Profiles", appName)

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
end

function DLTAddOn:OnDisable()
    -- Code that runs when the AddOn is disabled
    DLTAddOn:Disable()
end

function DLTAddOn:slashCommand(msg)
    if not msg or msg:trim() == "" then
        -- If no args are passed in the slash command we just want to toggle the window being shown
        if DLT_Parent_:IsShown() == true then
            DLT_Parent_:Hide()
        else
            DLT_Parent_:Show()
        end
    elseif msg == "options" then
        -- If options are passed as an arg in the slash command we want to option the blizzard options panel
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

-- Option Functions
function DLTAddOn:RefreshConfig()
    AceConfigRegistry:NotifyChange(appName)
end

function DLTAddOn:setAutoRecord(info, value)
    self.db.profile.autoRecord = value
    AceConfigRegistry:NotifyChange(appName)
end

function DLTAddOn:getAutoRecord(info)
    return self.db.profile.autoRecord
end

function DLTAddOn:openOptions(input)
    InterfaceOptionsFrame_OpenToCategory(appName .. " Options")
end

function DLTAddOn:toggleWindow(input)
    if windowShown then
        AceConfigDialog:Close(appName .. " Options")
    else
        AceConfigDialog:Open(appName .. " Options")
    end
end

function DLTAddOn:showFrame()
    DLT_MainWindow:Show()
end

function DLTAddOn:HideTooltip()
    print("Hiding Tooltip")
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
        DLTAddOn:Record_Stop();
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
    else
        DLTAddOn:Record_Start();
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
    end
end

function DLTAddOn:IsRecording()
    return DLT_Parent_ToggleRecordingBtn.recording;
end

function DLTAddOn:Record_Start()
    if (DLT_Parent_ToggleRecordingBtn.recording) then
        return;
    end
    DLT_Parent_ToggleRecordingBtn.recording = true;
    DLT_Parent_ToggleRecordingBtn:SetNormalTexture("Interface\\TimeManager\\ResetButton");
end

function DLTAddOn:Record_Stop()
    if (not DLT_Parent_ToggleRecordingBtn.recording) then
        return;
    end
    DLT_Parent_ToggleRecordingBtn.recording = false;
    DLT_Parent_ToggleRecordingBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up");
end

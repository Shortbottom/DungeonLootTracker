local addonName, addon = ...

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

local mainSettingsInfo = {
    name = addon.Title,
    handler = addon,
    type = "group",
    args = {
        info = {
            type = "header",
            name = "",
            desc = "Name of the Add On"
        }
    }
}

function addon:OnInitialize()
end

function addon:toggleWindow()
    if DLT_Parent_:IsShown() == true then
        DLT_Parent_:Hide()
    else
        DLT_Parent_:Show()
    end
end

function addon:ResetAllInstances()
    print("Ressetting all instances")
end

-- Functions to deal with starting and stopping recordings
function addon:ToggleRecording_OnClick(self)
    print(self.recording)
    if (self.recording) then
        addon:Record_Stop()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
    else
        addon:Record_Start()
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end
end

function addon:IsRecording()
    return DLT_Parent_ToggleRecordingBtn.recording
end

function addon:Record_Start()
    if (DLT_Parent_ToggleRecordingBtn.recording) then
        return
    end
    DLT_Parent_ToggleRecordingBtn.recording = true
    DLT_Parent_ToggleRecordingBtn:SetNormalTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Stop-Up")
    DLT_Parent_ToggleRecordingBtn:SetPushedTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Stop-Up")
end

function addon:Record_Stop()
    if (not DLT_Parent_ToggleRecordingBtn.recording) then
        return
    end
    DLT_Parent_ToggleRecordingBtn.recording = false
    DLT_Parent_ToggleRecordingBtn:SetNormalTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Record-Up")
end

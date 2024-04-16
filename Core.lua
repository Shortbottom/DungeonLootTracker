local addonName, addon = ...
local DLT_Parent_Frame = _G["DLT_Parent_"]
local DLT_RecButton = _G["DLT_Parent_ToggleRecordingBtn"]

function addon:toggleWindow()
  if DLT_Parent_Frame:IsShown() == true then
    DLT_Parent_Frame:Hide()
  else
    DLT_Parent_Frame:Show()
  end
end

function addon:ResetAllInstances()
  addon:Print("Ressetting all instances")
end

-- Functions to deal with starting and stopping recordings
function addon:ToggleRecording_OnClick(self)
  addon:Print(self.recording)
  if (self.recording) then
    addon:Record_Stop()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
  else
    addon:Record_Start()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
  end
end

function addon:IsRecording()
  return DLT_RecButton.recording
end

function addon:Record_Start()
  if (DLT_RecButton.recording) then
    return
  end
  DLT_RecButton.recording = true
  DLT_RecButton:SetNormalTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Stop-Up")
  DLT_RecButton:SetPushedTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Stop-Up")
end

function addon:Record_Stop()
  if (not DLT_RecButton.recording) then
    return
  end
  DLT_RecButton.recording = false
  DLT_RecButton:SetNormalTexture("Interface\\Addons\\DungeonLootTracker\\Images\\UI-Record-Up")
end

local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class MainFrame: AceModule
local mainFrame = addon:NewModule("MainFrame")

---Show/Hide a frame
function mainFrame:toggleFrame()
  local f = _G["DLT_Parent_"]
  if f == nil then
    return
  end
  if f:IsShown() == true then
    f:Hide()
  else
    f:Show()
  end
end

mainFrame:Enable()

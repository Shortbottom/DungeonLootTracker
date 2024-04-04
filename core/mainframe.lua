local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class MainFrame: AceModule
local mainFrame = addon:NewModule("MainFrame")

---Show/Hide a frame
---@param name string # Name of a frame as a string
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

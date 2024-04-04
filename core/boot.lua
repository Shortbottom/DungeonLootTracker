local addonName, root = ... --[[@type string, table]]

---@class DLT_Addon: AceModule
local addon = LibStub("AceAddon-3.0"):NewAddon(root, addonName, "AceConsole-3.0")

addon:SetDefaultModuleState(false)

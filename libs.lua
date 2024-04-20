local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

addon.Libs = {}
local libs = addon.Libs

libs.AceAddon = "AceAddon-3.0"
libs.AceConfig = "AceConfig-3.0"
libs.AceConfigDialog = "AceConfigDialog-3.0"
libs.AceConsole = "AceConsole-3.0"
libs.AceDBOptions = "AceDBOptions-3.0"
libs.LibDBIcon = "LibDBIcon-1.0"
libs.ShortyUtil = "Shorty_Util"

addon.Util = LibStub(addon.Libs.ShortyUtil)

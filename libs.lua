local addonName, addon = ... -- luacheck: ignore  -- Warns about overwriting addon before it's used but at this point it doesn't contain anything

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

local addonName, addon = ...
addon.Libs = {}
local libs = addon.Libs

libs.Shorty_Util = "Shorty_Util"

-- [[ Personal Libraries ]] --
addon.Util = LibStub(libs.Shorty_Util)

local addonName, _ = ...
local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale(addonName, "deDE")

if not L then return end

-- Localization strings
L["Gold"] = "Gold"
L["Silver"] = "Silber"
L["Copper"] = "Kupfer"

--Recording\main.lua
L["No Loot in Slot: "] = "No Loot in Slot: "
L["Unknown Slot Type: "] = "Unknown Slot Type: "

-- You can also use string format
--L["Greeting"] = "Hello, %s!"

-- End of localization

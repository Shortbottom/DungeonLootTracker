local addonName, _ = ...
local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale(addonName, "frFR")

if not L then return end

-- Localization strings
L["Gold"] = "Or"
L["Silver"] = "Argent"
L["Copper"] = "Cuivre"

--Recording\main.lua
L["No Loot in Slot: "] = "No Loot in Slot: "
L["Unknown Slot Type: "] = "Unknown Slot Type: "

-- End of localization

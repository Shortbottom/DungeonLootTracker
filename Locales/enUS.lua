local addonName, _ = ...
local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

if not L then return end

-- Localization strings
L["Gold"] = "Gold"
L["Silver"] = "Silver"
L["Copper"] = "Copper"
-- Add more localization strings here

-- You can also use string format
--L["Greeting"] = "Hello, %s!"

-- End of localization

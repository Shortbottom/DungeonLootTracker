local addonName = ... ---@type string
local L = LibStub:GetLibrary("AceLocale-3.0"):NewLocale(addonName, "enUS", true)

if not L then return end

L["AddonName"] = "DungeonLootTracker"

-- Localization strings
L["Gold"] = "Gold"
L["Silver"] = "Silver"
L["Copper"] = "Copper"
L["Money"] = "Money"

--Recording\main.lua
L["No Loot in Slot: "] = "No Loot in Slot: "
L["Unknown Slot Type: "] = "Unknown Slot Type: "

-- You can also use string format
--L["Greeting"] = "Hello, %s!"

-- End of localization

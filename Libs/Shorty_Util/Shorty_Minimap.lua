local addonName, addon = ...
addon.Minimap = {}
local lib = addon.Minimap

function lib.minimap_Click(input, button)
    if button == "LeftButton" then
        addon:toggleWindow()
    elseif button == "RightButton" then
        InterfaceOptionsFrame_OpenToCategory(AceConfigRegistry:GetOptionsTable(addon.Title))
        -- InterfaceAddOnsList_Update()
        -- InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        -- AceConfigDialog:SelectGroup("DungeonLootTracker_options")
    end
end

-- This contains all the functions that will be used within the Options-Minimap section
local addonName, addon = ...

-- Option Functions

-- CAUTION: LibDBIcon option to hide or show the minimap icon is a hide flag and we want to refer to it as a show flag
-- CAUTION: so when the user says to Show we need to store false in the settings table
function addon.setShowMinimap(info, value)
    self.db.profile.minimap.hide = not value
    if self.db.profile.minimap.hide then
        icon:Hide(addonName .. "_Minimap")
    else
        icon:Show(addonName .. "_Minimap")
    end
    addon.RefreshConfig(self)
end

-- INFO: LibDBIcon's option to lock the minimap is a lock flag which matches with the user setting so no need to reverse it
function addon.setLockMinimap(info, val)
    addon.db.profile.minimap.lock = val;
    if val then
        icon:Lock(addonName .. "_Minimap")
    else
        icon:Unlock(addonName .. "_Minimap")
    end
    addon.RefreshConfig(self)
end

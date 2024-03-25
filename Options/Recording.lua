-- This contains all the functions for the Options-Recording section
local addonName, addon = ...

function addon:setAutoRecord(info, value)
    self.db.profile.autoRecord = value
    addon.RefreshConfig(self)
end

function addon:getAutoRecord(info)
    return self.db.profile.autoRecord
end

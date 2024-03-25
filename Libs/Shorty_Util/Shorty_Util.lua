local addonName, addon = ...
addon.Util = {}

function addon.Util.DeepCopyTable(src, dest)
    for index, value in pairs(src) do
        if type(value) == "table" then
            dest[index] = {};
            lib.DeepCopyTable(value, dest[index]);
        else
            dest[index] = value;
        end
    end
end

function addon.Util.RefreshConfig()
    AceConfigRegistry:NotifyChange(appName)
end

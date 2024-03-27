local lib = LibStub:GetLibrary("Shorty_Util")

if not lib then
    return
end

function lib.toggleWindow()
    if DLT_Parent_:IsShown() == true then
        DLT_Parent_:Hide()
    else
        DLT_Parent_:Show()
    end
end

-- -- Embed my utilities
-- local mixins = {
--     "minimap_Click"
-- }

-- function lib:Embed(target)
--     for k, v in pairs(mixins) do
--         target[v] = self[v]
--     end
--     self.embeds[target] = true
--     return target
-- end

-- for addon in pairs(lib.embeds) do
--     lib.Embed(addon)
-- end

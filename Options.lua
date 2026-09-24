local _, addon = ...
local panel
local unlimitedCheck

StaticPopupDialogs.DLT_CONFIRM_UNLIMITED_SALES = {
    text = "Allow more than 11 sales per merchant visit? Some sold items may no longer be available to buy back.",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        addon.db.options.unlimitedSales = true
        if unlimitedCheck then unlimitedCheck:SetChecked(true) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function addon.ToggleOptions()
    if not panel then
        panel = CreateFrame("Frame", "DungeonLootTrackerOptions", UIParent, "BasicFrameTemplateWithInset")
        panel:SetSize(420, 520)
        panel:SetPoint("CENTER", 180, 0)
        panel.TitleText:SetText("Dungeon Loot Tracker - Options")
        table.insert(UISpecialFrames, "DungeonLootTrackerOptions")
        local y = -40
        local function Check(label, get, set)
            local button = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
            button:SetPoint("TOPLEFT", 16, y)
            button.Text:SetText(label)
            button:SetScript("OnShow", function(self) self:SetChecked(get()) end)
            button:SetChecked(get())
            button:SetScript("OnClick", function(self) set(self:GetChecked()) end)
            y = y - 32
            return button
        end
        Check("Auto-sell completed runs at merchants", function() return addon.db.options.autoSell end,
            function(value) addon.db.options.autoSell = value end)
        Check("Open history when entering a dungeon or raid", function() return addon.db.options.autoOpen end,
            function(value) addon.db.options.autoOpen = value end)
        unlimitedCheck = Check("Allow more than 11 sales per visit", function() return addon.db.options.unlimitedSales end,
            function(value)
                if value then
                    unlimitedCheck:SetChecked(false)
                    StaticPopup_Show("DLT_CONFIRM_UNLIMITED_SALES")
                else
                    addon.db.options.unlimitedSales = false
                end
            end)
        for quality = 0, 4 do
            local value = quality
            Check("Sell " .. _G["ITEM_QUALITY" .. value .. "_DESC"], function() return addon.db.options.qualities[value] end,
                function(checked) addon.db.options.qualities[value] = checked end)
        end
        Check("Keep weapons and armor", function() return addon.db.options.keepEquipment end,
            function(value) addon.db.options.keepEquipment = value end)
        Check("Keep crafting reagents", function() return addon.db.options.keepReagents end,
            function(value) addon.db.options.keepReagents = value end)
        local note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        note:SetPoint("TOPLEFT", 20, y - 12)
        note:SetWidth(375)
        note:SetJustifyH("LEFT")
        note:SetText("Selling more than 11 stacks may remove earlier items from Buyback.\n\nFilters apply to manual and automatic sales. Quest items, equipment-set items, refundable items, and qualities above Epic are always kept. Mixed stacks need an empty bag slot.")
        panel:Hide()
    end
    panel:SetShown(not panel:IsShown())
end

function addon.HideOptions()
    if panel then panel:Hide() end
end

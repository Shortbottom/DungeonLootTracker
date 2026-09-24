local _, addon = ...
local merchantOpen, queue, pending, ticker, merchantReadyTimer
local MAX_SALES_PER_VISIT = 11
local salesThisVisit = 0
local inventoryReady, inventoryTimer, worldAvailable = true, nil, true
local SALE_LIMIT_MESSAGE = "11-sale limit reached. Check Buyback, then click Sell loot to sell another batch of up to 11."

function addon.BagSnapshot()
    local counts, slots = {}, {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or 5 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info then
                local key = addon.ItemKey(info.hyperlink)
                if key then
                    counts[key] = (counts[key] or 0) + info.stackCount
                    slots[#slots + 1] = { bag = bag, slot = slot, key = key, info = info }
                end
            end
        end
    end
    return counts, slots
end

function addon.InventoryUnavailable()
    worldAvailable = false
    inventoryReady = false
    if inventoryTimer then inventoryTimer:Cancel(); inventoryTimer = nil end
end

function addon.InventoryAvailable()
    worldAvailable = true
    if inventoryTimer then inventoryTimer:Cancel() end
    inventoryReady = false
    local previous, attempts = nil, 0
    inventoryTimer = C_Timer.NewTicker(0.25, function()
        attempts = attempts + 1
        local counts = addon.BagSnapshot()
        local stable = previous ~= nil and C_Container.GetContainerNumSlots(0) > 0
        -- A wholly empty snapshot after previously populated bags is not enough
        -- evidence to retire saved loot during startup or a loading screen.
        if not next(counts) and next(addon.db.bagCounts) then stable = false end
        if stable then
            for key, count in pairs(counts) do if previous[key] ~= count then stable = false; break end end
            for key, count in pairs(previous) do if counts[key] ~= count then stable = false; break end end
        end
        previous = counts
        if stable or attempts >= 8 then
            inventoryTimer:Cancel()
            inventoryTimer = nil
            if stable then
                inventoryReady = true
                if not pending then addon.ReconcileBags(counts) end
                if merchantOpen and addon.db.options.autoSell then addon.StartSelling() end
            end
        end
    end)
end

function addon.SaleAllowed(slot, options)
    local info = slot.info
    if info.isLocked then return nil, "locked" end
    if info.hasNoValue then return nil, "no vendor value" end
    if info.hasLoot then return nil, "contains loot" end
    if not options.qualities[info.quality] then return nil, "quality filter" end
    local quest = C_Container.GetContainerItemQuestInfo(slot.bag, slot.slot)
    if quest and (quest.isQuestItem or quest.questID) then return nil, "quest item" end
    local purchase = C_Container.GetContainerItemPurchaseInfo(slot.bag, slot.slot, false)
    if purchase and purchase.refundSeconds > 0 then return nil, "refundable" end
    if C_Container.GetContainerItemEquipmentSetInfo(slot.bag, slot.slot) then return nil, "equipment set" end
    local values = { C_Item.GetItemInfo(info.hyperlink) }
    local price, class, reagent = values[11], values[12], values[17]
    if not price then return nil, "item data not loaded" end
    if price <= 0 then return nil, "no vendor value" end
    if options.keepEquipment and (class == 2 or class == 4) then return nil, "keep weapons/armor" end
    if options.keepReagents and reagent then return nil, "keep reagents" end
    return price
end

local function EmptySlot()
    -- A general-purpose bag is required when splitting a mixed stack.
    for bag = 0, NUM_BAG_SLOTS or 4 do
        local free, family = C_Container.GetContainerNumFreeSlots(bag)
        if free > 0 and family == 0 then
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                if not C_Container.GetContainerItemInfo(bag, slot) then return bag, slot end
            end
        end
    end
end

local function Finish(message)
    if ticker then ticker:Cancel(); ticker = nil end
    queue, pending = nil, nil
    if message then print("Dungeon Loot Tracker: " .. message) end
    if addon.Refresh then addon.Refresh() end
end

local function Advance()
    if not inventoryReady then return end
    local counts, slots = addon.BagSnapshot()
    if pending then
        local p = pending
        if p.phase == "split" then
            local info = C_Container.GetContainerItemInfo(p.bag, p.slot)
            if info and not info.isLocked and addon.ItemKey(info.hyperlink) == p.key and info.stackCount == p.quantity then
                pending = nil -- Rescan and recheck filters before using the split stack.
            elseif GetTime() - p.started > 3 then
                Finish("Stack split could not be confirmed; selling stopped.")
            end
            return
        end
        local removed = p.beforeCount - (counts[p.key] or 0)
        local income = GetMoney() - p.beforeMoney
        if removed == p.quantity and income == p.expected then
            local run = addon.db.runs[p.runID]
            local item = run.items[p.key]
            item.QtyRemaining = math.max(0, item.QtyRemaining - p.quantity)
            item.QtySold = item.QtySold + p.quantity
            item.isSold = item.QtySold >= item.looted and 1 or 0
            run.saleIncome = run.saleIncome + income
            run.sales[#run.sales + 1] = { time = time(), link = item.link, count = p.quantity, copper = income }
            -- Consume this loss before reconciling unrelated inventory changes.
            addon.db.bagCounts[p.key] = math.max(0, (addon.db.bagCounts[p.key] or 0) - p.quantity)
            pending = nil
            addon.ReconcileBags(counts)
            if addon.Refresh then addon.Refresh() end
        elseif GetTime() - p.started > 3 then
            -- Ambiguous money changes must not be presented as confirmed proceeds.
            addon.ReconcileBags(counts)
            Finish("Sale could not be confirmed. Selling stopped; no income credited for that transaction.")
        end
        return
    end
    addon.ReconcileBags(counts)
    if not addon.db.options.unlimitedSales and salesThisVisit >= MAX_SALES_PER_VISIT then Finish(SALE_LIMIT_MESSAGE); return end
    if queue.automatic and not addon.db.options.autoSell then Finish("Auto-sell disabled."); return end
    if not merchantOpen or not MerchantFrame:IsShown() or InCombatLockdown() or CursorHasItem()
        or (InRepairMode and InRepairMode()) then
        Finish("Selling stopped.")
        return
    end
    table.sort(slots, function(a, b) return a.info.stackCount < b.info.stackCount end)
    local skipped = {}
    local function Skip(reason) skipped[reason] = (skipped[reason] or 0) + 1 end
    for _, runID in ipairs(queue) do
        local run = addon.db.runs[runID]
        for _, slot in ipairs(slots) do
            local item = run.items[slot.key]
            local price, reason
            if item and item.isSold ~= 1 and item.QtyRemaining > 0 then
                price, reason = addon.SaleAllowed(slot, addon.db.options)
                if reason then Skip(reason) end
            end
            if price then
                local quantity = math.min(item.QtyRemaining, slot.info.stackCount)
                if quantity < slot.info.stackCount then
                    local bag, target = EmptySlot()
                    if bag then
                        pending = { phase = "split", bag = bag, slot = target, key = slot.key, quantity = quantity, started = GetTime() }
                        C_Container.SplitContainerItem(slot.bag, slot.slot, quantity)
                        if CursorHasItem() then C_Container.PickupContainerItem(bag, target) end
                        return
                    end
                    Skip("no free slot to split stack")
                else
                    pending = { phase = "sell", key = slot.key, runID = runID, quantity = quantity,
                        beforeCount = counts[slot.key], beforeMoney = GetMoney(), expected = price * quantity, started = GetTime() }
                    -- Count requests conservatively, even if confirmation later fails.
                    salesThisVisit = salesThisVisit + 1
                    C_Container.UseContainerItem(slot.bag, slot.slot)
                    return
                end
            end
        end
    end
    local reasons = {}
    for reason, count in pairs(skipped) do reasons[#reasons + 1] = count .. " stack(s): " .. reason end
    table.sort(reasons)
    Finish(#reasons > 0 and ("Sale pass finished. Kept " .. table.concat(reasons, "; ") .. ".")
        or "Sale pass finished. No further matching, tracked items in bags.")
end

function addon.StartSelling(runID)
    if queue then return end
    if not inventoryReady then
        print("Dungeon Loot Tracker: waiting for bag contents to finish loading.")
        return
    end
    if not merchantOpen or not MerchantFrame:IsShown() then
        print("Dungeon Loot Tracker: open a merchant first.")
        return
    end
    -- A deliberate manual click authorizes another batch; automatic retries do not.
    if runID then salesThisVisit = 0 end
    if not addon.db.options.unlimitedSales and salesThisVisit >= MAX_SALES_PER_VISIT then
        print("Dungeon Loot Tracker: " .. SALE_LIMIT_MESSAGE)
        return
    end
    queue = { automatic = not runID }
    local remaining = 0
    for index, run in ipairs(addon.db.runs) do
        if run.endedAt and (not runID or runID == index) then
            queue[#queue + 1] = index
            for _, item in pairs(run.items) do
                if item.isSold ~= 1 then remaining = remaining + item.QtyRemaining end
            end
        end
    end
    if #queue == 0 then Finish("End the recording before selling its loot."); return end
    if remaining == 0 then Finish("No recorded unsold quantities remain for this selection."); return end
    ticker = C_Timer.NewTicker(0.2, Advance)
end

function addon.MerchantShown()
    if not merchantOpen then salesThisVisit = 0 end
    merchantOpen = true
    if merchantReadyTimer then merchantReadyTimer:Cancel(); merchantReadyTimer = nil end
    if not addon.db.options.autoSell then return end
    -- MERCHANT_SHOW can reach us before Blizzard shows MerchantFrame.
    -- Wait for the UI to be ready without treating that delay as user error.
    local attempts = 0
    merchantReadyTimer = C_Timer.NewTicker(0.1, function()
        attempts = attempts + 1
        local ready = MerchantFrame and MerchantFrame:IsShown()
        if not merchantOpen or not addon.db.options.autoSell or ready or attempts >= 20 then
            merchantReadyTimer:Cancel()
            merchantReadyTimer = nil
            if merchantOpen and addon.db.options.autoSell and ready and inventoryReady then addon.StartSelling() end
        end
    end)
end

function addon.MerchantClosed()
    merchantOpen = false
    if merchantReadyTimer then merchantReadyTimer:Cancel(); merchantReadyTimer = nil end
    -- A sale already sent can still finish; no further sale will be issued.
end

function addon.BagsChanged()
    if not inventoryReady then
        if worldAvailable and not inventoryTimer then addon.InventoryAvailable() end
        return
    end
    if not pending then addon.ReconcileBags(addon.BagSnapshot()) end
end

function addon.SellingBusy()
    return queue ~= nil
end

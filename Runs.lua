local _, addon = ...
local db

function addon.Initialize(saved)
    db = saved
    db.runs = db.runs or {}
    db.options = db.options or { autoSell = false, qualities = { [0] = true }, keepEquipment = true, keepReagents = true }
    if db.options.autoOpen == nil then db.options.autoOpen = false end
    if db.options.unlimitedSales == nil then db.options.unlimitedSales = false end
    db.bagCounts = db.bagCounts or {}
    local counts = {}
    for key, count in pairs(db.bagCounts) do
        local normalized = addon.ItemKey(key) or key
        counts[normalized] = (counts[normalized] or 0) + count
    end
    db.bagCounts = counts
    for _, run in ipairs(db.runs) do
        run.items, run.sales = run.items or {}, run.sales or {}
        run.money, run.saleIncome = run.money or 0, run.saleIncome or 0
        local items = {}
        for key, item in pairs(run.items) do
            if item.QtySold == nil then item.QtySold = item.sold or 0 end
            if item.QtyRemaining == nil then item.QtyRemaining = item.remaining or 0 end
            item.sold, item.remaining = nil, nil
            local normalized = addon.ItemKey(key) or key
            if items[normalized] then
                local existing = items[normalized]
                existing.looted = existing.looted + item.looted
                existing.QtyRemaining = existing.QtyRemaining + item.QtyRemaining
                existing.QtySold = existing.QtySold + item.QtySold
            else
                items[normalized] = item
            end
        end
        run.items = items
        for _, item in pairs(run.items) do
            -- Older records store only the sold quantity, not the completion flag.
            item.isSold = item.looted > 0 and item.QtySold >= item.looted and 1 or 0
        end
    end
    addon.db = db
end

local function SameInstance(run, info)
    return info and run.instanceID == info.instanceID
        and run.instanceType == info.instanceType and run.difficultyID == info.difficultyID
end

local function MarkVisitExit(run, now, unknown)
    while run do
        run.leftAt, run.exitUnknown = now, unknown
        run = db.runs[run.previousSegment]
    end
end

function addon.IsRecording()
    local run = db.runs[db.currentRun]
    return run ~= nil and run.endedAt == nil
end

function addon.UpdateInstance(info, now, initialLogin)
    if db.suppressedInstance then
        if SameInstance(db.suppressedInstance, info) and not initialLogin then return end
        local leftAt
        if not initialLogin then leftAt = now end
        MarkVisitExit(db.runs[db.suppressedInstance.previousSegment], leftAt, initialLogin)
        db.suppressedInstance = nil
    end
    local run = db.runs[db.currentRun]
    if run and initialLogin then
        -- We cannot infer when the player left while the addon was offline.
        run.endedAt = run.endedAt or run.lastSeenAt or run.enteredAt
        run.endReason = run.endReason or "interrupted"
        MarkVisitExit(run, nil, true)
        db.currentRun = nil
        run = nil
    end
    if run and not SameInstance(run, info) then
        MarkVisitExit(run, now)
        run.endedAt = run.endedAt or now
        run.endReason = run.endReason or "left"
        db.currentRun = nil
        run = nil
    end
    if not run and info then
        run = {
            name = info.name, instanceID = info.instanceID,
            instanceType = info.instanceType, difficultyID = info.difficultyID,
            difficultyName = info.difficultyName, enteredAt = now,
            loot = {}, items = {}, money = 0, sales = {}, saleIncome = 0,
        }
        db.runs[#db.runs + 1] = run
        db.currentRun = #db.runs
    end
    if run then run.lastSeenAt = now end
    return run
end

function addon.Start(info, now)
    if not info then return false end
    if db.suppressedInstance then
        if SameInstance(db.suppressedInstance, info) then
            local previousSegment = db.suppressedInstance.previousSegment
            db.suppressedInstance = nil
            addon.UpdateInstance(info, now).previousSegment = previousSegment
            return true
        end
    end
    local previous = db.runs[db.currentRun]
    if previous and SameInstance(previous, info) then
        if not previous.endedAt then return false end
        local previousIndex = db.currentRun
        db.currentRun = nil
        local run = addon.UpdateInstance(info, now)
        run.previousSegment = previousIndex
    else
        addon.UpdateInstance(info, now)
    end
    return true
end

function addon.DeleteRun(index, now)
    local removed = db.runs[index]
    if not removed then return false end
    if addon.SellingBusy and addon.SellingBusy() then return false end
    if db.currentRun == index then
        -- Keep only visit identity so loot events do not restart a deleted run.
        db.suppressedInstance = {
            instanceID = removed.instanceID, instanceType = removed.instanceType,
            difficultyID = removed.difficultyID, previousSegment = removed.previousSegment,
        }
        db.currentRun = nil
    elseif db.currentRun and db.currentRun > index then
        db.currentRun = db.currentRun - 1
    end
    table.remove(db.runs, index)
    local function Remap(record)
        if record.previousSegment == index then record.previousSegment = removed.previousSegment end
        if record.previousSegment and record.previousSegment > index then
            record.previousSegment = record.previousSegment - 1
        end
    end
    for _, run in ipairs(db.runs) do Remap(run) end
    if db.suppressedInstance then Remap(db.suppressedInstance) end
    return true
end

function addon.Stop(now)
    local run = db.runs[db.currentRun]
    if not run or run.endedAt then return false end
    run.endedAt, run.endReason = now, "manual"
    return true
end

function addon.RecordLoot(message, now, link, count)
    local run = db.runs[db.currentRun]
    if not run or run.endedAt then return end
    run.loot[#run.loot + 1] = { time = now, message = message }
    if link and count and count > 0 then
        local key = addon.ItemKey(link)
        if key then
            local item = run.items[key] or {
                link = link,
                looted = 0, -- Total quantity picked up during this run.
                QtyRemaining = 0, -- Tracked quantity still available for sale, subject to filters.
                QtySold = 0, -- Quantity confirmed sold through the addon for this run.
                isSold = 0, -- 1 when the full looted quantity has been sold; otherwise 0.
            }
            run.items[key] = item
            item.looted, item.QtyRemaining = item.looted + count, item.QtyRemaining + count
            item.isSold = 0
        end
    end
    run.lastSeenAt = now
end

function addon.RecordMoney(amount, message, now)
    local run = db.runs[db.currentRun]
    if not run or run.endedAt then return end
    run.money = run.money + (amount or 0)
    if not amount then run.unparsedMoney = (run.unparsedMoney or 0) + 1 end
    run.loot[#run.loot + 1] = { time = now, message = message }
    run.lastSeenAt = now
end

-- Inventory losses outside our sale queue retire tracked quantities first.
-- Reacquiring an identical item later never restores its sale eligibility.
function addon.ReconcileBags(counts)
    for key, previous in pairs(db.bagCounts) do
        local lost = math.max(0, previous - (counts[key] or 0))
        for index = #db.runs, 1, -1 do
            local item = db.runs[index].items[key]
            if item and lost > 0 then
                local used = math.min(item.QtyRemaining, lost)
                item.QtyRemaining, lost = item.QtyRemaining - used, lost - used
            end
        end
    end
    db.bagCounts = counts
end

function addon.Checkpoint(now)
    local run = db.runs[db.currentRun]
    if run then run.lastSeenAt = now end
end


local addonName, addon = ...
local window, logText, logContent, database
local selectedRun
local recordingButton
local detailView = false
local runRows, detailButtons = {}, {}
local listHeader, historyScroll
local page, PAGE_SIZE = 1, 10
local previousPage, nextPage, pageLabel, totalLabel
local columnLabels = {}

local function Money(copper)
    return string.format("%dg %ds %dc", math.floor(copper / 10000), math.floor(copper / 100) % 100, copper % 100)
end

local function Timestamp(value)
    return date("%d %b %Y %H:%M:%S", value)
end

local function Duration(run)
    local seconds = math.max(0, (run.endedAt or time()) - run.enteredAt)
    return string.format("%02d:%02d:%02d", math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
end

local function CurrentInstance()
    local name, kind, difficultyID, difficultyName, _, _, _, instanceID = GetInstanceInfo()
    if kind ~= "party" and kind ~= "raid" then return end
    return { name = name, instanceType = kind, difficultyID = difficultyID,
        difficultyName = difficultyName, instanceID = instanceID }
end

local function Refresh()
    if not logText or not database then return end
    local contentWidth = window:GetWidth() - 60
    logContent:SetWidth(contentWidth)
    logText:SetWidth(contentWidth)
    listHeader:SetWidth(contentWidth)
    columnLabels[2]:SetPoint("TOPLEFT", contentWidth - 256, 0)
    columnLabels[3]:SetPoint("TOPLEFT", contentWidth - 156, 0)
    local total = 0
    for _, run in ipairs(database.runs) do total = total + run.money + run.saleIncome end
    totalLabel:SetText("Total earned across all runs: " .. Money(total))
    local pageCount = math.max(1, math.ceil(#database.runs / PAGE_SIZE))
    page = math.min(page, pageCount)
    pageLabel:SetText("Page " .. page .. " / " .. pageCount)
    previousPage:SetEnabled(page > 1)
    nextPage:SetEnabled(page < pageCount)
    previousPage:SetShown(not detailView)
    nextPage:SetShown(not detailView)
    pageLabel:SetShown(not detailView)
    if recordingButton then recordingButton:SetText(addon.IsRecording() and "Stop run" or "Start run") end
    if detailView and not database.runs[selectedRun] then detailView = false end
    for _, button in ipairs(detailButtons) do button:SetShown(detailView) end
    local displayedRun = database.runs[selectedRun]
    local hasUnsoldItems = false
    if displayedRun then
        for _, item in pairs(displayedRun.items) do
            if item.isSold ~= 1 then hasUnsoldItems = true; break end
        end
    end
    detailButtons[2]:SetEnabled(hasUnsoldItems)
    listHeader:SetShown(not detailView)
    for _, row in ipairs(runRows) do row:Hide() end
    if not detailView then
        logText:SetText(#database.runs == 0 and "No runs recorded yet. Enter a dungeon or raid to begin." or "")
        local firstIndex = #database.runs - (page - 1) * PAGE_SIZE
        local lastIndex = math.max(1, firstIndex - PAGE_SIZE + 1)
        for index = firstIndex, lastIndex, -1 do
            local rowNumber = firstIndex - index + 1
            local row = runRows[rowNumber]
            if not row then
                row = CreateFrame("Button", nil, logContent)
                row:SetSize(contentWidth, 24)
                row:SetPoint("TOPLEFT", 0, -(rowNumber - 1) * 24)
                local background = row:CreateTexture(nil, "BACKGROUND")
                background:SetAllPoints()
                if rowNumber % 2 == 0 then
                    background:SetColorTexture(0.18, 0.18, 0.18, 0.8)
                else
                    background:SetColorTexture(0.05, 0.05, 0.05, 0.8)
                end
                row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                local function Label(x, y, width, font)
                    local label = row:CreateFontString(nil, "OVERLAY", font)
                    label:SetPoint("TOPLEFT", x, y)
                    label:SetWidth(width)
                    label:SetJustifyH("LEFT")
                    label:SetWordWrap(false)
                    return label
                end
                row.nameLabel = Label(4, -5, 290, "GameFontNormal")
                row.durationLabel = Label(304, -5, 90, "GameFontHighlight")
                row.earnedLabel = Label(404, -5, 152, "GameFontHighlight")
                row:SetScript("OnClick", function(self)
                    selectedRun, detailView = self.runIndex, true
                    historyScroll:SetVerticalScroll(0)
                    Refresh()
                end)
                runRows[rowNumber] = row
            end
            local run = database.runs[index]
            row:SetWidth(contentWidth)
            row.nameLabel:SetWidth(contentWidth - 270)
            row.durationLabel:SetPoint("TOPLEFT", contentWidth - 256, -5)
            row.earnedLabel:SetPoint("TOPLEFT", contentWidth - 156, -5)
            row.runIndex = index
            row.nameLabel:SetText(run.name)
            row.durationLabel:SetText(Duration(run))
            row.earnedLabel:SetText(Money(run.money + run.saleIncome))
            row:SetShown(true)
        end
        logContent:SetHeight(math.max(24, (firstIndex - lastIndex + 1) * 24))
        return
    end
    local lines = {}
    selectedRun = selectedRun or #database.runs
    local index = selectedRun
    local run = database.runs[index]
    if run then
        lines[#lines + 1] = "Run " .. index .. " / " .. #database.runs .. ": " .. run.name .. " - " .. (run.instanceType == "raid" and "Raid" or "Dungeon")
            .. " - " .. run.difficultyName
        lines[#lines + 1] = "Entered: " .. Timestamp(run.enteredAt)
        lines[#lines + 1] = run.leftAt and ("Left: " .. Timestamp(run.leftAt))
            or (run.exitUnknown and "Left: unknown (session interrupted)" or "Still inside")
        if run.endedAt then
            lines[#lines + 1] = (run.endReason == "interrupted" and "Last seen: " or "Finished: ")
                .. Timestamp(run.endedAt) .. " (" .. run.endReason .. ")"
        end
        local duration = math.max(0, (run.endedAt or time()) - run.enteredAt)
        lines[#lines + 1] = string.format("Duration: %02d:%02d:%02d%s", math.floor(duration / 3600),
            math.floor(duration / 60) % 60, duration % 60, run.endReason == "interrupted" and " (incomplete)" or "")
        lines[#lines + 1] = "Looted money: " .. Money(run.money) .. " | Sales: " .. Money(run.saleIncome)
        lines[#lines + 1] = "Total earned: " .. Money(run.money + run.saleIncome)
        if run.unparsedMoney then lines[#lines + 1] = "Some money messages could not be totaled; see the log below." end
        for _, loot in ipairs(run.loot) do
            lines[#lines + 1] = date("%H:%M:%S", loot.time) .. " " .. loot.message
        end
        if #run.loot == 0 then lines[#lines + 1] = "No loot recorded." end
        for _, sale in ipairs(run.sales) do
            lines[#lines + 1] = "Sold " .. sale.link .. " x" .. sale.count .. " for " .. Money(sale.copper)
        end
        lines[#lines + 1] = " "
    end
    if #database.entries > 0 then lines[#lines + 1] = "Legacy loot (not assigned to runs)" end
    for index = #database.entries, 1, -1 do
        local entry = database.entries[index]
        lines[#lines + 1] = date("%d %b %H:%M", entry.time) .. " - " .. entry.dungeon
            .. "\n" .. entry.message
    end
    logText:SetText(#lines > 0 and table.concat(lines, "\n\n")
        or "Dungeon and raid visits will be recorded automatically.")
    logContent:SetHeight(math.max(1, logText:GetStringHeight()))
end
addon.Refresh = Refresh

local function ToggleWindow()
    if not window then
        window = CreateFrame("Frame", "DungeonLootTrackerWindow", UIParent, "BasicFrameTemplateWithInset")
        window:SetSize(500, 400)
        local position = database.options.windowPosition
        if position and type(position.x) == "number" and type(position.y) == "number" then
            window:SetPoint("CENTER", UIParent, "CENTER", position.x, position.y)
        else
            window:SetPoint("CENTER")
        end
        window:SetMovable(true)
        window:SetClampedToScreen(true)
        window:EnableMouse(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local x, y = self:GetCenter()
            local parentX, parentY = UIParent:GetCenter()
            if x and y and parentX and parentY then
                database.options.windowPosition = { x = x - parentX, y = y - parentY }
            end
        end)
        window.TitleText:SetText("Dungeon Loot Tracker")

        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        historyScroll = scroll
        scroll:SetPoint("TOPLEFT", 16, -106)
        scroll:SetPoint("BOTTOMRIGHT", -34, 72)
        local content = CreateFrame("Frame", nil, scroll)
        logContent = content
        content:SetSize(560, 1)
        scroll:SetScrollChild(content)
        logText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        logText:SetPoint("TOPLEFT")
        logText:SetWidth(560)
        logText:SetJustifyH("LEFT")
        logText:SetJustifyV("TOP")
        listHeader = CreateFrame("Frame", nil, window)
        listHeader:SetPoint("TOPLEFT", 16, -78)
        listHeader:SetSize(560, 20)
        for index, column in ipairs({ {"Dungeon / Raid", 4}, {"Duration", 304}, {"Total earned", 404} }) do
            local label = listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("TOPLEFT", column[2], 0)
            label:SetText(column[1])
            columnLabels[index] = label
        end
        window:SetScript("OnShow", Refresh)
        local elapsed = 0
        window:SetScript("OnUpdate", function(_, delta)
            elapsed = elapsed + delta
            if elapsed >= 1 then elapsed = 0; Refresh() end
        end)
        local function Button(label, x, width, onClick)
            local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
            button:SetSize(width, 24)
            button:SetPoint("TOPLEFT", x, -36)
            button:SetText(label)
            button:SetScript("OnClick", onClick)
            return button
        end
        Button("Older", 12, 65, function() selectedRun = math.max(1, (selectedRun or #database.runs) - 1); Refresh() end)
        Button("Newer", 80, 65, function() selectedRun = math.min(#database.runs, (selectedRun or 0) + 1); Refresh() end)
        Button("Sell loot", 148, 95, function() addon.StartSelling(selectedRun) end)
        recordingButton = Button("Start run", 246, 95, function()
            if addon.IsRecording() then
                addon.Stop(time())
                selectedRun = database.currentRun
            elseif addon.Start(CurrentInstance(), time()) then
                selectedRun = database.currentRun
            else
                print("Dungeon Loot Tracker: enter a dungeon or raid to start recording.")
            end
            Refresh()
        end)
        Button("Options", 344, 95, addon.ToggleOptions)
        local deleteButton = Button("Delete run", 12, 95, function()
            if addon.SellingBusy() then
                print("Dungeon Loot Tracker: wait for selling to finish before deleting a run.")
                return
            end
            if addon.DeleteRun(selectedRun, time()) then
                selectedRun = math.max(1, math.min(selectedRun, #database.runs))
                Refresh()
            end
        end)
        deleteButton:SetPoint("TOPLEFT", 12, -66)
        table.insert(UISpecialFrames, "DungeonLootTrackerWindow")
        window:Hide()
    end
    window:SetShown(not window:IsShown())
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("CHAT_MSG_LOOT")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_LEAVING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("PLAYER_LOGOUT")
events:RegisterEvent("CHAT_MSG_MONEY")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        if type(DLTMinimalDB) ~= "table" then DLTMinimalDB = {} end
        if type(DLTMinimalDB.entries) ~= "table" then DLTMinimalDB.entries = {} end
        database = DLTMinimalDB
        addon.Initialize(database)
        addon.InventoryUnavailable()
        events:UnregisterEvent("ADDON_LOADED")
        return
    end
    if not database then return end
    if event == "PLAYER_LEAVING_WORLD" then addon.InventoryUnavailable(); return end
    if event == "MERCHANT_SHOW" then addon.MerchantShown(); return end
    if event == "MERCHANT_CLOSED" then addon.MerchantClosed(); return end
    if event == "BAG_UPDATE_DELAYED" then addon.BagsChanged(); return end
    if event == "PLAYER_LOGOUT" then
        addon.Checkpoint(time())
        return
    end
    if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        local initialLogin, reloading = ...
        local previousRunCount = #database.runs
        addon.UpdateInstance(CurrentInstance(), time(), event == "PLAYER_ENTERING_WORLD" and initialLogin and not reloading)
        addon.InventoryAvailable()
        if not detailView then selectedRun = nil end
        Refresh()
        if database.options.autoOpen and #database.runs > previousRunCount and (not window or not window:IsShown()) then
            ToggleWindow()
        end
        return
    end
    local message = ...
    if event == "CHAT_MSG_MONEY" then
        if issecretvalue and issecretvalue(message) then return end
        if type(message) ~= "string" then return end
        addon.UpdateInstance(CurrentInstance(), time())
        addon.RecordMoney(addon.ParseMoney(message), message, time())
        Refresh()
        return
    end
    local playerGUID = select(12, ...)
    -- Restricted event payloads cannot be inspected or saved.
    if issecretvalue and (issecretvalue(message) or issecretvalue(playerGUID)) then return end
    if type(message) ~= "string" or playerGUID ~= UnitGUID("player") then return end
    addon.UpdateInstance(CurrentInstance(), time())
    local link, count = addon.ParseLoot(message)
    addon.RecordLoot(message, time(), link, count)
    Refresh()
end)

SLASH_DUNGEONLOOTTRACKER1 = "/dlt"
SLASH_DUNGEONLOOTTRACKER2 = "/dungeonloottracker"
StaticPopupDialogs.DLT_CONFIRM_CLEAR = {
    text = "This will delete all recorded data. Do you want to proceed?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if addon.SellingBusy() then
            print("Dungeon Loot Tracker: wait for selling to finish before clearing data.")
            return
        end
        DLTMinimalDB = { entries = {}, options = database.options }
        DLTRecordings_DB = nil
        database = DLTMinimalDB
        addon.Initialize(database)
        -- Do not immediately restart a recording from the next loot event.
        database.suppressedInstance = CurrentInstance()
        addon.BagsChanged()
        selectedRun = nil
        detailView = false
        addon.HideOptions()
        Refresh()
        print("Dungeon Loot Tracker: all recorded data cleared. Options unchanged.")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
SlashCmdList.DUNGEONLOOTTRACKER = function(message)
    local command = (message or ""):match("^%s*(.-)%s*$"):lower()
    if command == "" then
        ToggleWindow()
    elseif command == "clear" and database then
        if addon.SellingBusy() then print("Dungeon Loot Tracker: wait for selling to finish."); return end
        StaticPopup_Show("DLT_CONFIRM_CLEAR")
    elseif command == "options" and database then
        addon.ToggleOptions()
    elseif command == "sell" and database then
        addon.StartSelling(selectedRun or #database.runs)
    elseif command == "stop" and database then
        print(addon.Stop(time()) and "Dungeon Loot Tracker: recording stopped until your next visit."
            or "Dungeon Loot Tracker: no recording is active.")
        Refresh()
    else
        print("Dungeon Loot Tracker: \n /dlt toggles the log; \n /dlt stop ends recording; \n /dlt sell sells the selected run; \n /dlt options opens filters; \n /dlt clear asks to delete all data; \n /dlt help shows help.")
    end
end

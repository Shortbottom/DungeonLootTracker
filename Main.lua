local addonName = ...
local window, logText, logContent, database
local MAX_ENTRIES = 200

local function Refresh()
    if not logText or not database then return end
    local lines = {}
    for index = #database.entries, 1, -1 do
        local entry = database.entries[index]
        lines[#lines + 1] = date("%d %b %H:%M", entry.time) .. " - " .. entry.dungeon
            .. "\n" .. entry.message
    end
    logText:SetText(#lines > 0 and table.concat(lines, "\n\n")
        or "Your dungeon loot will appear here automatically.")
    logContent:SetHeight(math.max(1, logText:GetStringHeight()))
end

local function ToggleWindow()
    if not window then
        window = CreateFrame("Frame", "DungeonLootTrackerWindow", UIParent, "BasicFrameTemplateWithInset")
        window:SetSize(500, 400)
        window:SetPoint("CENTER")
        window:SetMovable(true)
        window:SetClampedToScreen(true)
        window:EnableMouse(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        window.TitleText:SetText("Dungeon Loot Tracker")

        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, -36)
        scroll:SetPoint("BOTTOMRIGHT", -34, 16)
        local content = CreateFrame("Frame", nil, scroll)
        logContent = content
        content:SetSize(440, 1)
        scroll:SetScrollChild(content)
        logText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        logText:SetPoint("TOPLEFT")
        logText:SetWidth(440)
        logText:SetJustifyH("LEFT")
        logText:SetJustifyV("TOP")
        window:SetScript("OnShow", Refresh)
        table.insert(UISpecialFrames, "DungeonLootTrackerWindow")
        window:Hide()
    end
    window:SetShown(not window:IsShown())
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("CHAT_MSG_LOOT")
events:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        if type(DLTMinimalDB) ~= "table" then DLTMinimalDB = {} end
        if type(DLTMinimalDB.entries) ~= "table" then DLTMinimalDB.entries = {} end
        database = DLTMinimalDB
        while #database.entries > MAX_ENTRIES do table.remove(database.entries, 1) end
        events:UnregisterEvent("ADDON_LOADED")
        return
    end
    if not database then return end
    local message = ...
    local playerGUID = select(12, ...)
    -- Restricted event payloads cannot be inspected or saved.
    if issecretvalue and (issecretvalue(message) or issecretvalue(playerGUID)) then return end
    if type(message) ~= "string" or playerGUID ~= UnitGUID("player") then return end
    local dungeon, instanceType = GetInstanceInfo()
    if instanceType ~= "party" then return end
    database.entries[#database.entries + 1] = {
        time = time(), dungeon = dungeon, message = message,
    }
    while #database.entries > MAX_ENTRIES do table.remove(database.entries, 1) end
    Refresh()
end)

SLASH_DUNGEONLOOTTRACKER1 = "/dlt"
SLASH_DUNGEONLOOTTRACKER2 = "/dungeonloottracker"
SlashCmdList.DUNGEONLOOTTRACKER = function(message)
    local command = (message or ""):match("^%s*(.-)%s*$"):lower()
    if command == "" then
        ToggleWindow()
    elseif command == "clear" and database then
        database.entries = {}
        Refresh()
        print("Dungeon Loot Tracker: loot log cleared.")
    else
        print("Dungeon Loot Tracker: /dlt toggles the log; /dlt clear clears it; /dlt help shows help.")
    end
end

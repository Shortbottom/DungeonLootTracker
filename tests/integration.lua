local addon, frames, fontStrings = {}, {}, {}
UIParent, UISpecialFrames, SlashCmdList = {}, {}, {}
StaticPopupDialogs, YES, NO = {}, "Yes", "No"
local shownPopup
function StaticPopup_Show(name) shownPopup = StaticPopupDialogs[name] end
local now, kind = 100, "none"
function time() return now end
date = os.date
function UnitGUID() return "player" end
function GetInstanceInfo() return "Test Dungeon", kind, 2, "Heroic", 5, 0, false, 123 end
LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
YOU_LOOT_MONEY = "You loot %s"
GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = "%d Gold", "%d Silver", "%d Copper"
for i = 0, 4 do _G["ITEM_QUALITY" .. i .. "_DESC"] = "Quality " .. i end
local methods = {}
function UIParent:GetCenter() return 960, 540 end
for _, name in ipairs({"SetSize", "SetPoint", "SetMovable", "SetClampedToScreen", "EnableMouse", "RegisterForDrag",
    "SetWidth", "SetHeight", "SetJustifyH", "SetJustifyV", "SetScrollChild", "StartMoving", "StopMovingOrSizing",
    "SetHighlightTexture", "SetVerticalScroll", "SetAllPoints", "SetColorTexture", "SetWordWrap", "SetResizable",
    "SetResizeBounds", "SetNormalTexture", "SetPushedTexture", "StartSizing", "ClearAllPoints"}) do
    methods[name] = function() end
end
function methods:SetSize(width, height) self.width, self.height = width, height end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetEnabled(enabled) self.enabled = enabled end
function methods:SetPoint(...) self.anchor = {...} end
function methods:GetCenter() return 1160, 440 end
function methods:SetScript(event, fn) self.scripts[event] = fn end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetText(text) self.value = text end
function methods:GetStringHeight() return 100 end
function methods:SetChecked(value) self.checked = value end
function methods:GetChecked() return self.checked end
function methods:Hide() self.shown = false end
function methods:IsShown() return self.shown end
function methods:SetShown(value)
    self.shown = value
    if value and self.scripts.OnShow then self.scripts.OnShow(self) end
end
local function Widget()
    return setmetatable({scripts={}, events={}, shown=true}, {__index=methods})
end
function methods:CreateFontString()
    local widget = Widget()
    fontStrings[#fontStrings + 1] = widget
    return widget
end
function methods:CreateTexture() return Widget() end
function CreateFrame(_, name, _, template)
    local frame = Widget()
    if template == "BasicFrameTemplateWithInset" then frame.TitleText = Widget() end
    if template == "UICheckButtonTemplate" then frame.Text = Widget() end
    if name then _G[name] = frame end
    frames[#frames + 1] = frame
    return frame
end
C_Container = {GetContainerNumSlots=function() return 0 end}
C_Timer = {NewTicker=function() return {Cancel=function() end} end}
for _, path in ipairs({"Parsing.lua", "Runs.lua", "Selling.lua", "Options.lua", "Main.lua"}) do
    assert(loadfile(path))("DungeonLootTracker", addon)
end
local events = frames[1]
local function Emit(event, ...) events.scripts.OnEvent(events, event, ...) end
Emit("ADDON_LOADED", "DungeonLootTracker")
Emit("PLAYER_ENTERING_WORLD", true, false)
SlashCmdList.DUNGEONLOOTTRACKER("")
assert(DungeonLootTrackerWindow:IsShown())
DungeonLootTrackerWindow.scripts.OnDragStop(DungeonLootTrackerWindow)
assert(DLTMinimalDB.options.windowPosition.x == 200 and DLTMinimalDB.options.windowPosition.y == -100)
local recordingButton, backButton
for _, frame in ipairs(frames) do
    if frame.value == "Start run" then recordingButton = frame end
    if frame.value == "Back to runs" then backButton = frame end
end
local function SelectRun(index)
    if backButton:IsShown() then backButton.scripts.OnClick() end
    for _, frame in ipairs(frames) do
        if frame.runIndex == index and frame:IsShown() then frame.scripts.OnClick(frame); return frame end
    end
    error("Missing run row " .. index)
end
assert(recordingButton)
recordingButton.scripts.OnClick()
assert(#DLTMinimalDB.runs == 0 and recordingButton.value == "Start run")
kind = "party"
Emit("PLAYER_ENTERING_WORLD", false, false)
assert(recordingButton.value == "Stop run")
local link = "|cffffffff|Hitem:2592::::|h[Wool Cloth]|h|r"
Emit("CHAT_MSG_LOOT", string.format(LOOT_ITEM_SELF_MULTIPLE, link, 6), nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"other")
assert(#DLTMinimalDB.runs[1].loot == 0)
Emit("CHAT_MSG_LOOT", string.format(LOOT_ITEM_SELF_MULTIPLE, link, 6), nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,"player")
Emit("CHAT_MSG_MONEY", "You loot 2 Gold")
assert(DLTMinimalDB.runs[1].money == 20000 and #DLTMinimalDB.runs[1].loot == 1)
-- Legacy coin messages must also stay out of the item detail view.
DLTMinimalDB.runs[1].loot[2] = {time=100, message="You loot 2 Gold"}
now, kind = 190, "none"
Emit("PLAYER_ENTERING_WORLD", false, false)
assert(DLTMinimalDB.runs[1].endedAt == 190)
local row = SelectRun(1)
local sellButton
for _, frame in ipairs(frames) do
    if frame.value == "Sell loot" then sellButton = frame end
end
assert(sellButton.enabled, "unsold loot enables selling even when filtered")
local trackedItem = DLTMinimalDB.runs[1].items[addon.ItemKey(link)]
trackedItem.isSold = 1
addon.Refresh()
assert(not sellButton.enabled, "fully sold run disables the sell button")
trackedItem.isSold = 0
trackedItem.QtyRemaining = 0
addon.Refresh()
assert(sellButton.enabled, "unsold flag keeps button usable even without eligible quantity")
trackedItem.QtyRemaining = 6
assert(row.nameLabel.value == "Test Dungeon" and row.durationLabel.value == "00:01:30")
assert(row.earnedLabel.value == "2g 0s 0c")
assert(fontStrings[1].value:find("Duration: 00:01:30", 1, true))
assert(fontStrings[1].value:find("Total earned: 2g 0s 0c", 1, true))
assert(not fontStrings[1].value:find("You loot 2 Gold", 1, true))
assert(fontStrings[1].value:find("Wool Cloth", 1, true))
assert(recordingButton.value == "Start run")
kind, now = "party", 200
Emit("PLAYER_ENTERING_WORLD", false, false)
SelectRun(1)
assert(recordingButton.value == "Stop run")
now = 210
recordingButton.scripts.OnClick()
assert(recordingButton.value == "Start run" and DLTMinimalDB.runs[2].endedAt == 210)
now = 220
recordingButton.scripts.OnClick()
assert(recordingButton.value == "Stop run" and #DLTMinimalDB.runs == 3)
assert(DLTMinimalDB.runs[2].endedAt == 210 and DLTMinimalDB.runs[3].enteredAt == 220)
Emit("PLAYER_ENTERING_WORLD", false, true)
assert(#DLTMinimalDB.runs == 3 and recordingButton.value == "Stop run")
kind, now = "none", 230
Emit("PLAYER_ENTERING_WORLD", false, false)
assert(recordingButton.value == "Start run")
assert(DLTMinimalDB.runs[2].leftAt == 230 and DLTMinimalDB.runs[3].leftAt == 230)
local deleteButton
for _, frame in ipairs(frames) do
    if frame.value == "Delete run" then deleteButton = frame end
end
assert(deleteButton)
deleteButton.scripts.OnClick()
assert(#DLTMinimalDB.runs == 2 and not backButton:IsShown())
kind, now = "party", 240
Emit("PLAYER_ENTERING_WORLD", false, false)
SelectRun(3)
deleteButton.scripts.OnClick()
assert(#DLTMinimalDB.runs == 2 and recordingButton.value == "Start run")
Emit("CHAT_MSG_MONEY", "You loot 2 Gold")
assert(#DLTMinimalDB.runs == 2, "deleted active run must not restart from loot")
recordingButton.scripts.OnClick()
assert(#DLTMinimalDB.runs == 3 and recordingButton.value == "Stop run")
SelectRun(2)
deleteButton.scripts.OnClick()
assert(#DLTMinimalDB.runs == 2 and DLTMinimalDB.currentRun == 2 and addon.IsRecording())
SlashCmdList.DUNGEONLOOTTRACKER("options")
assert(DungeonLootTrackerOptions:IsShown())
local count = 0
for _, frame in ipairs(frames) do
    if frame.Text then
        count = count + 1
        if count == 1 then frame:SetChecked(true); frame.scripts.OnClick(frame) end
    end
end
assert(count == 10 and DLTMinimalDB.options.autoSell == true)
local unlimitedCheck
for _, frame in ipairs(frames) do
    if frame.Text and frame.Text.value == "Allow more than 11 sales per batch" then unlimitedCheck = frame end
end
assert(unlimitedCheck and not DLTMinimalDB.options.unlimitedSales)
unlimitedCheck:SetChecked(true); unlimitedCheck.scripts.OnClick(unlimitedCheck)
assert(shownPopup == StaticPopupDialogs.DLT_CONFIRM_UNLIMITED_SALES)
assert(not unlimitedCheck:GetChecked() and not DLTMinimalDB.options.unlimitedSales)
assert(shownPopup.hideOnEscape and not shownPopup.OnCancel)
shownPopup.OnAccept()
assert(unlimitedCheck:GetChecked() and DLTMinimalDB.options.unlimitedSales)
unlimitedCheck:SetChecked(false); unlimitedCheck.scripts.OnClick(unlimitedCheck)
assert(not DLTMinimalDB.options.unlimitedSales)
local beforeClear = DLTMinimalDB
local preservedOptions = DLTMinimalDB.options
preservedOptions.autoOpen = true
preservedOptions.qualities[2] = true
preservedOptions.keepEquipment = false
SlashCmdList.DUNGEONLOOTTRACKER("clear")
assert(shownPopup and shownPopup.button1 == "Yes" and shownPopup.button2 == "No")
assert(shownPopup.hideOnEscape and DLTMinimalDB == beforeClear and #DLTMinimalDB.runs == 2)
-- No has no callback: dismissing the popup must not mutate saved state.
assert(not shownPopup.OnCancel)
local busy = addon.SellingBusy
addon.SellingBusy = function() return true end
shownPopup.OnAccept()
assert(DLTMinimalDB == beforeClear, "must recheck sale activity when accepting")
addon.SellingBusy = busy
dltDB, DLTRecordings_DB = {old=true}, {old=true}
shownPopup.OnAccept()
assert(DLTMinimalDB ~= beforeClear and #DLTMinimalDB.runs == 0 and #DLTMinimalDB.entries == 0)
assert(dltDB.old and not DLTRecordings_DB)
assert(DLTMinimalDB.options == preservedOptions and DLTMinimalDB.options.autoSell)
assert(DLTMinimalDB.options.windowPosition.x == 200 and DLTMinimalDB.options.windowPosition.y == -100)
assert(DLTMinimalDB.options.autoOpen and DLTMinimalDB.options.qualities[2] and not DLTMinimalDB.options.keepEquipment)
assert(recordingButton.value == "Start run" and not DungeonLootTrackerOptions:IsShown())
Emit("CHAT_MSG_MONEY", "You loot 2 Gold")
assert(#DLTMinimalDB.runs == 0)
SlashCmdList.DUNGEONLOOTTRACKER("options")
for _, frame in ipairs(frames) do
    if frame.Text and frame.Text.value == "Auto-sell completed runs at merchants" then
        frame:SetChecked(true)
        frame.scripts.OnClick(frame)
        assert(DLTMinimalDB.options.autoSell, "options must update the replacement database")
    end
end
recordingButton.scripts.OnClick()
assert(#DLTMinimalDB.runs == 1 and recordingButton.value == "Stop run")
DungeonLootTrackerWindow:Hide()
kind = "none"
Emit("PLAYER_ENTERING_WORLD", false, false)
assert(not DungeonLootTrackerWindow:IsShown())
kind = "raid"
Emit("PLAYER_ENTERING_WORLD", false, false)
assert(DungeonLootTrackerWindow:IsShown(), "auto-open on raid entry")
Emit("ZONE_CHANGED_NEW_AREA")
assert(DungeonLootTrackerWindow:IsShown(), "duplicate zone event must not toggle the window closed")
DungeonLootTrackerWindow:Hide()
Emit("PLAYER_ENTERING_WORLD", false, true)
assert(not DungeonLootTrackerWindow:IsShown(), "reload must not reopen the same visit")
kind = "none"
Emit("PLAYER_ENTERING_WORLD", false, false)
DLTMinimalDB.options.autoOpen = false
kind = "party"
Emit("PLAYER_ENTERING_WORLD", false, false)
assert(not DungeonLootTrackerWindow:IsShown(), "auto-open disabled")
kind = "none"
Emit("PLAYER_ENTERING_WORLD", false, false)
DLTMinimalDB.options.autoOpen = true
kind = "party"
Emit("PLAYER_ENTERING_WORLD", false, false)
assert(DungeonLootTrackerWindow:IsShown(), "auto-open on dungeon entry")
-- Recreate the addon UI with the saved database, as after a reload.
DungeonLootTrackerWindow:SetSize(800, 600)
for _, frame in ipairs(frames) do
    if frame.scripts.OnMouseUp then frame.scripts.OnMouseUp(frame, "LeftButton") end
end
assert(DLTMinimalDB.options.windowSize.width == 800 and DLTMinimalDB.options.windowSize.height == 600)
assert(loadfile("Main.lua"))("DungeonLootTracker", addon)
events = frames[#frames]
Emit("ADDON_LOADED", "DungeonLootTracker")
SlashCmdList.DUNGEONLOOTTRACKER("")
local anchor = DungeonLootTrackerWindow.anchor
assert(anchor[1] == "CENTER" and anchor[2] == UIParent and anchor[4] == 200 and anchor[5] == -100)
assert(DungeonLootTrackerWindow:GetWidth() == 800 and DungeonLootTrackerWindow:GetHeight() == 600)
DLTMinimalDB.runs = {}
for index = 1, 23 do
    DLTMinimalDB.runs[index] = {name="Run " .. index, enteredAt=100, endedAt=160,
        leftAt=160, endReason="left", difficultyName="Normal", instanceType="party",
        money=100, saleIncome=200, loot={}, sales={}, items={}}
end
addon.Refresh()
local nextPage, previousPage, footer, pageText
for _, frame in ipairs(frames) do
    if frame.value == "Next" then nextPage = frame end
    if frame.value == "Previous" then previousPage = frame end
end
for _, label in ipairs(fontStrings) do
    if label.value and label.value:find("Total earned across all runs:", 1, true) then footer = label end
    if label.value and label.value:find("Page ", 1, true) then pageText = label end
end
local function VisibleRows()
    local rows = {}
    -- Old mocked UI frames belong to the earlier simulated session.
    for _, frame in ipairs(frames) do
        if frame.runIndex and frame:IsShown() and frame:GetHeight() == 24 then rows[#rows + 1] = frame end
    end
    return rows
end
-- Hide rows from the first simulated session before counting the new window.
for _, frame in ipairs(frames) do
    if frame.runIndex and frame.nameLabel.value == "Test Dungeon" then frame:Hide() end
end
assert(#VisibleRows() == 10 and not previousPage.enabled and nextPage.enabled)
assert(footer.value == "Total earned across all runs: 0g 69s 0c")
nextPage.scripts.OnClick()
assert(#VisibleRows() == 10 and pageText.value == "Page 2 / 3")
nextPage.scripts.OnClick()
assert(#VisibleRows() == 3 and not nextPage.enabled and pageText.value == "Page 3 / 3")
assert(footer.value == "Total earned across all runs: 0g 69s 0c", "footer must include other pages")
previousPage.scripts.OnClick()
assert(#VisibleRows() == 10 and pageText.value == "Page 2 / 3")
print("Event routing, history UI, timing, options, and saved position tests passed")

local addon = {}
for _, path in ipairs({"Parsing.lua", "Runs.lua", "Selling.lua"}) do assert(loadfile(path))("DungeonLootTracker", addon) end
local link = "|cffffffff|Hitem:2592::::::::80:::::|h[Wool Cloth]|h|r"
local key = addon.ItemKey(link)
local bag, cursor, money, clock, callback, active
local open, freeSlots, failSale, noMoney, combat = true, true, false, false, false
local db
NUM_TOTAL_EQUIPPED_BAG_SLOTS, NUM_BAG_SLOTS = 0, 0
MerchantFrame = { IsShown = function() return open end }
function InCombatLockdown() return combat end
function CursorHasItem() return cursor ~= nil end
function GetTime() return clock end
function time() return clock end
function GetMoney() return money end
C_Timer = { NewTicker = function(_, fn) callback = fn; active = true; return { Cancel = function() active = false end } end }
C_Container = {
    GetContainerNumSlots = function() return freeSlots and 2 or 1 end,
    GetContainerItemInfo = function(_, slot)
        if not bag[slot] then return end
        return {hyperlink=link, stackCount=bag[slot], quality=1, itemID=2592}
    end,
    GetContainerNumFreeSlots = function() return freeSlots and not bag[2] and 1 or 0, 0 end,
    GetContainerItemQuestInfo = function() return {} end,
    GetContainerItemPurchaseInfo = function() end,
    GetContainerItemEquipmentSetInfo = function() return false end,
    SplitContainerItem = function(_, slot, count) bag[slot] = bag[slot] - count; cursor = count end,
    PickupContainerItem = function(_, slot) assert(not bag[slot]); bag[slot], cursor = cursor, nil end,
    UseContainerItem = function(_, slot)
        assert(open and not combat)
        if failSale then return end
        if not noMoney then money = money + bag[slot] * 10 end
        bag[slot] = nil
    end,
}
C_Item = { GetItemInfo = function() return "Wool", link, 1, 1, 1, "Trade", "Cloth", 200, "", 0, 10, 7, 5, 0, 0, nil, true end }
local info = {name="Dungeon", instanceID=1, instanceType="party", difficultyID=1, difficultyName="Normal"}
local function Setup()
    addon.MerchantClosed()
    bag, cursor, money, clock, active = {[1]=10}, nil, 1000, 0, false
    open, freeSlots, failSale, noMoney, combat = true, true, false, false, false
    db = {}
    addon.Initialize(db)
    db.options.qualities[1], db.options.keepReagents = true, false
    addon.BagsChanged()
    addon.UpdateInstance(info, 1)
    addon.RecordLoot("6 Wool", 2, link, 6)
    bag[1] = 16
    addon.BagsChanged()
    addon.UpdateInstance(nil, 3)
    addon.MerchantShown()
end
local function TickAll()
    for _ = 1, 40 do
        if not active then break end
        clock = clock + 0.25
        callback()
    end
    assert(not active, "sale queue did not finish")
end
Setup()
addon.StartSelling(1)
TickAll()
assert(bag[1] == 10 and not bag[2], "must preserve the 10 original cloth")
assert(db.runs[1].items[key].sold == 6 and db.runs[1].saleIncome == 60)
addon.StartSelling(1); TickAll()
assert(bag[1] == 10 and money == 1060, "repeat must not resell")

Setup(); freeSlots = false
addon.StartSelling(1); TickAll()
assert(bag[1] == 16 and db.runs[1].saleIncome == 0, "full bags must preserve mixed stacks")

Setup(); db.options.keepReagents = true
addon.StartSelling(1); TickAll()
assert(bag[1] == 16 and money == 1000, "reagent filter")

Setup(); db.options.qualities[1] = false
addon.StartSelling(1); TickAll()
assert(bag[1] == 16, "quality filter")

Setup(); failSale = true
addon.StartSelling(1); TickAll()
assert(db.runs[1].saleIncome == 0 and db.runs[1].items[key].sold == 0, "failed sale cannot earn money")

Setup(); noMoney = true
addon.StartSelling(1); TickAll()
assert(db.runs[1].saleIncome == 0 and db.runs[1].items[key].remaining == 0, "unconfirmed removal must retire eligibility")

Setup(); bag[1] = 10; addon.BagsChanged(); bag[1] = 16; addon.BagsChanged()
addon.StartSelling(1); TickAll()
assert(bag[1] == 16, "consumed loot must not be replaced by later untracked acquisitions")

Setup(); addon.UpdateInstance(info, 4); addon.RecordLoot("4 Wool", 5, link, 4)
bag[1] = 20; addon.BagsChanged(); addon.UpdateInstance(nil, 6)
addon.StartSelling(2); TickAll()
assert(bag[1] == 16 and db.runs[2].saleIncome == 40 and db.runs[1].items[key].remaining == 6)
addon.StartSelling(1); TickAll()
assert(bag[1] == 10 and db.runs[1].saleIncome == 60)

Setup(); db.options.autoSell = true; addon.MerchantShown(); TickAll()
assert(bag[1] == 10, "automatic sales")
Setup(); db.options.autoSell = true; open = false
addon.MerchantShown()
clock = clock + 0.25; callback()
assert(not addon.SellingBusy() and bag[1] == 16, "wait for merchant frame visibility")
open = true; TickAll()
assert(bag[1] == 10 and db.runs[1].saleIncome == 60, "auto-sell after delayed merchant display")
Setup(); db.options.autoSell = true; open = false
addon.MerchantShown(); addon.MerchantClosed(); open = true; TickAll()
assert(bag[1] == 16 and not addon.SellingBusy(), "close cancels deferred auto-sell")
Setup(); db.options.autoSell = true; open = false
addon.MerchantShown(); TickAll()
assert(bag[1] == 16 and not addon.SellingBusy(), "merchant readiness timeout must not sell")
Setup(); addon.StartSelling(1); open = false; addon.MerchantClosed(); TickAll()
assert(bag[1] == 16, "merchant closure must prevent use")
Setup(); combat = true; addon.StartSelling(1); TickAll()
assert(bag[1] == 16, "combat must prevent use")
-- Thirteen separate stacks must stop after eleven buyback entries.
Setup()
bag = {}
for slot = 1, 13 do bag[slot] = 1 end
C_Container.GetContainerNumSlots = function() return 13 end
db.runs[1].items[key].remaining = 13
db.runs[1].items[key].looted = 13
db.bagCounts = addon.BagSnapshot()
db.options.autoSell = true
addon.MerchantShown(); TickAll()
assert(db.runs[1].items[key].sold == 11 and db.runs[1].saleIncome == 110)
assert(db.runs[1].items[key].remaining == 2)
addon.StartSelling(1); TickAll()
assert(db.runs[1].items[key].sold == 11, "manual retry cannot bypass visit limit")
addon.MerchantShown(); TickAll()
assert(db.runs[1].items[key].sold == 11, "duplicate merchant event cannot reset limit")
addon.MerchantClosed(); addon.MerchantShown(); TickAll()
assert(db.runs[1].items[key].sold == 13 and db.runs[1].saleIncome == 130)
Setup()
bag = {}
for slot = 1, 13 do bag[slot] = 1 end
db.runs[1].items[key].remaining = 13
db.runs[1].items[key].looted = 13
db.bagCounts = addon.BagSnapshot()
db.options.unlimitedSales = true
addon.StartSelling(1); TickAll()
assert(db.runs[1].items[key].sold == 13, "confirmed unlimited option bypasses the visit cap")
print("Quantity protection, filters, sale accounting, and failure tests passed")

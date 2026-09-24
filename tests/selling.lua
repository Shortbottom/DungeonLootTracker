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
assert(db.runs[1].items[key].QtySold == 6 and db.runs[1].saleIncome == 60)
assert(db.runs[1].items[key].isSold == 1, "confirmed full sale sets the sold flag")
db.runs[1].items[key].isSold = nil
addon.Initialize(db)
assert(db.runs[1].items[key].isSold == 1, "old records infer sold status from quantities")
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
assert(db.runs[1].saleIncome == 0 and db.runs[1].items[key].QtySold == 0, "failed sale cannot earn money")
assert(db.runs[1].items[key].isSold == 0, "failed sale must not set sold flag")

Setup(); noMoney = true
addon.StartSelling(1); TickAll()
assert(db.runs[1].saleIncome == 0 and db.runs[1].items[key].QtyRemaining == 0, "unconfirmed removal must retire eligibility")

Setup(); bag[1] = 10; addon.BagsChanged(); bag[1] = 16; addon.BagsChanged()
addon.StartSelling(1); TickAll()
assert(bag[1] == 16, "consumed loot must not be replaced by later untracked acquisitions")

Setup(); addon.UpdateInstance(info, 4); addon.RecordLoot("4 Wool", 5, link, 4)
bag[1] = 20; addon.BagsChanged(); addon.UpdateInstance(nil, 6)
addon.StartSelling(2); TickAll()
assert(bag[1] == 16 and db.runs[2].saleIncome == 40 and db.runs[1].items[key].QtyRemaining == 6)
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
db.runs[1].items[key].QtyRemaining = 13
db.runs[1].items[key].looted = 13
db.bagCounts = addon.BagSnapshot()
db.options.autoSell = true
addon.MerchantShown(); TickAll()
assert(db.runs[1].items[key].QtySold == 11 and db.runs[1].saleIncome == 110)
assert(db.runs[1].items[key].QtyRemaining == 2)
assert(db.runs[1].items[key].isSold == 0, "partial sale leaves item available for next batch")
addon.MerchantShown(); TickAll()
assert(db.runs[1].items[key].QtySold == 11, "duplicate merchant event cannot reset limit")
addon.StartSelling(1); TickAll()
assert(db.runs[1].items[key].QtySold == 13 and db.runs[1].saleIncome == 130)
assert(db.runs[1].items[key].isSold == 1, "last batch marks item fully sold")
Setup()
bag = {}
for slot = 1, 13 do bag[slot] = 1 end
db.runs[1].items[key].QtyRemaining = 13
db.runs[1].items[key].looted = 13
db.bagCounts = addon.BagSnapshot()
db.options.unlimitedSales = true
addon.StartSelling(1); TickAll()
assert(db.runs[1].items[key].QtySold == 13, "confirmed unlimited option bypasses the visit cap")
print("Quantity protection, filters, sale accounting, and failure tests passed")
-- Loading screens expose incomplete bag contents; never interpret them as losses.
Setup()
addon.InventoryUnavailable()
local actualBag = bag
bag = {}
addon.BagsChanged()
assert(db.runs[1].items[key].QtyRemaining == 6)
addon.InventoryAvailable()
clock = clock + 0.25; callback()
bag = actualBag
clock = clock + 0.25; callback()
clock = clock + 0.25; callback()
assert(db.runs[1].items[key].QtyRemaining == 6, "loading must preserve the six looted items")
addon.StartSelling(1); TickAll()
assert(db.runs[1].items[key].QtySold == 6 and bag[1] == 10)
print("Loading-screen inventory regression passed")
Setup()
db.runs[1].items[key].QtyRemaining = 0
local restored = addon.RecoverRun(db.runs[1])
assert(restored == 6 and bag[1] == 16 and money == 1000, "recovery must not sell")
assert(db.runs[1].items[key].QtyRemaining == 6)
addon.StartSelling(1); TickAll()
assert(bag[1] == 10 and db.runs[1].saleIncome == 60)
assert(addon.RecoverRun(db.runs[1]) == 0, "sold items must not be recovered again")
Setup()
db.runs[1].items[key].QtyRemaining = 0
addon.UpdateInstance(info, 4)
addon.RecordLoot("Other run loot", 5, link, 14)
addon.UpdateInstance(nil, 6)
assert(addon.RecoverRun(db.runs[1]) == 2, "recovery must respect quantities reserved by another run")
assert(addon.RecoverRun({}) == nil, "deleted run cannot be recovered")
print("Confirmed recovery quantity tests passed")
Setup()
local chatLink = "|cnIQ0:|Hitem:2783::::::::74:1467::1:1:6657:2:9:74:28:215:::::|h[Shoddy Blunderbuss]|h|r"
local bagLink = "|cnIQ0:|Hitem:2783::::::::74:1467::1:1:6657:2:28:215:9:74:::::|h[Shoddy Blunderbuss]|h|r"
local oldKey = chatLink:match("|H(item:[^|]+)|h")
db.runs[1].items = {[oldKey]={link=chatLink, looted=1, QtyRemaining =1, QtySold =0}}
db.bagCounts = {[oldKey]=1}
addon.Initialize(db)
link, key = bagLink, addon.ItemKey(bagLink)
bag = {[1]=1}
assert(db.runs[1].items[key].QtyRemaining == 1 and db.bagCounts[key] == 1)
addon.BagsChanged()
addon.StartSelling(1); TickAll()
assert(not bag[1] and db.runs[1].items[key].QtySold == 1, "existing records must sell reordered bag links")
print("Existing-record modifier-order sale regression passed")
local legacy = db.runs[1].items[key]
legacy.sold, legacy.remaining = 1, 0
legacy.QtySold, legacy.QtyRemaining = nil, nil
addon.Initialize(db)
assert(legacy.QtySold == 1 and legacy.QtyRemaining == 0 and legacy.isSold == 1)
assert(legacy.sold == nil and legacy.remaining == nil, "legacy fields must be removed")
legacy.sold, legacy.remaining = 99, 99
addon.Initialize(db)
assert(legacy.QtySold == 1 and legacy.QtyRemaining == 0, "new quantity fields take precedence")
assert(legacy.sold == nil and legacy.remaining == nil)

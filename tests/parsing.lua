local addon = {}
assert(loadfile("Parsing.lua"))("DungeonLootTracker", addon)
LOOT_ITEM_SELF = "You receive loot: %s."
LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %sx%d."
YOU_LOOT_MONEY = "You loot %s"
LOOT_MONEY_SPLIT = "Your share of the loot is %s."
YOU_LOOT_MONEY_GUILD = "You loot %s (%s deposited to guild bank)"
GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = "%d Gold", "%d Silver", "%d Copper"
local link = "|cffffffff|Hitem:2592::::::::80:::::|h[Wool Cloth]|h|r"
local parsed, count = addon.ParseLoot(string.format(LOOT_ITEM_SELF_MULTIPLE, link, 6))
assert(parsed == link and count == 6)
parsed, count = addon.ParseLoot(string.format(LOOT_ITEM_SELF, link))
assert(parsed == link and count == 1)
assert(addon.ItemKey(link) == "item:2592::::::::80:::::")
local reversed = addon.MatchFormat("6 copies of cloth", "%2$d copies of %1$s")
assert(reversed[1] == "cloth" and tonumber(reversed[2]) == 6)
assert(addon.ParseMoney("You loot 1 Gold, 2 Silver, 3 Copper") == 10203)
assert(addon.ParseMoney("Your share of the loot is 20 Silver.") == 2000)
assert(addon.ParseMoney("You loot 1,234 Gold") == 12340000)
assert(addon.ParseMoney("You loot 1 234 Gold") == 12340000)
assert(addon.ParseMoney("You loot 2 Silver (1 Gold deposited to guild bank)") == 200)
assert(addon.ParseMoney("Unknown money message") == nil)
print("Localized loot and money parsing tests passed")
local chat = "item:2783::::::::74:1467::1:1:6657:2:9:74:28:215:::::"
local bag = "item:2783::::::::74:1467::1:1:6657:2:28:215:9:74:::::"
assert(addon.ItemKey(chat) == addon.ItemKey(bag), "modifier order must not change item identity")
assert(addon.ItemKey(chat) ~= addon.ItemKey(bag:gsub("6657", "6658")), "bonus variants must stay distinct")
assert(addon.ItemKey(chat) ~= addon.ItemKey(bag:gsub("28:215", "28:216")), "modifier values must stay distinct")

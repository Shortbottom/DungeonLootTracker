local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local const = addon:GetModule("Constants")

---@class ShortyUtil: AceModule
local util = addon:GetModule("ShortyUtil")

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class RecordsDB: AceModule
local rDB = addon:GetModule("RecordsDB")

---@class Merchant: AceModule, AceMessage
local merchant = addon:NewModule("Merchant")

LibStub("AceEvent-3.0"):Embed(merchant)

local C = C_Container
local _FindItemInBags, _FindEmptyBagSlot

local merchantMessages = {
  ["merchant/Show"] = "merchantShow",
  ["merchant/Close"] = "merchantClosed",
}

function merchant:OnInitialize()
  for k, v in pairs(merchantMessages) do
    merchant:RegisterMessage(k, v)
  end
end

function merchant:merchantShow(_)
  addon:Print("38: Merchant Show")

  --- I: Don't want to actually sell anything at the moment

  --[[

  local recordID = rDB:GetLastRecordID()

  local itemTable = rDB:GetItemTable(recordID)
  local soldCount = 0

  --- Loop through the items in the recording
  for _, item in ipairs(itemTable) do
    --- If the sold count is 10, then we have sold enough items and can break out of the loop
    --- This is so that the player can buy back an item if they want
    if soldCount == 10 then
      addon:Print("Don't sell any more so you can buy back")
      break
    end

    --- Find the item in the player's bags
    local found, bag, slot = FindItemInBags(item.itemID, item.quantity)

    addon:Print("55: item = " .. item.itemLink .. "; found = " .. tostring(found) .. "; bag = " .. tostring(bag) .. "; slot = " .. tostring(slot))

    --- If the item is found in the player's bags, then we can sell it
    if found then
      --- Find out how many of the items to sell
      local recordQty = item.quantity
      --- Find out how many of the items they player has in their bag
      local bagQty = util:GetContainerStackCount(bag, slot)

      addon:Print("64: recordQty = ", recordQty, "; bagQty = ", bagQty, "\n")

      -- If the quantity in the record is the same as the stack count just sell the item
      if recordQty == bagQty then
        addon:Print("Selling " .. recordQty .. " of " .. item.itemLink)
        --C.UseContainerItem(bag, slot)
        soldCount = soldCount + 1
      elseif recordQty < bagQty then -- Need to split the stack and sell the record quantity
        addon:Print("Splitting " .. recordQty .. " of " .. item.itemLink)
        -- local hasEmpty, emptyBag, _ = FindEmptyBagSlot()
        -- if hasEmpty then
        --   C.SplitContainerItem(bag, slot, recordQty)
        --   if emptyBag == 0 then
        --     PutItemInBackpack()
        --   else
        --     PutItemInBag(emptyBag)
        --   end
        --   found, bag, slot = FindItemInBags(item.itemID, recordQty)
        --   C.UseContainerItem(bag, slot)
        --   soldCount = soldCount + 1
        --   addon:Print("Sold " .. recordQty .. " of " .. item.itemLink)
        -- end
      else -- ? If the quantity in the record is greater than or equal to the stack count, do we sell what there is or do something else?
        addon:Print("Selling ", recordQty .. " of " .. item.itemLink, "\n")
        --C.UseContainerItem(bag, slot)
        soldCount = soldCount + 1
      end
      addon:Print("soldCount = ", soldCount, "")
      print("   ")
    end
  end
  --]]
end

function merchant:merchantClosed(_)
  addon:Print("Merchant Closed")
end

---FindItemInBags searches for an item with the given itemID in the player's bags.
---It iterates through all the bags and slots to find the item.
---If the item is found, it returns true along with the bag and slot numbers.
---If the item is not found, it returns false along with nil values for bag and slot.
---@param itemID number The ID of the item to search for.
---@param stack? number The quantity of the item to search for.
---@return boolean found, number|nil bag, number|nil slot If a match was found The bag and slot numbers where the item is found, or nil if not found.
FindItemInBags = function (itemID, stack)
  addon:Print("FindItemInBags: itemID = " .. itemID .. "; Stack = " .. tostring(stack))
  for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
    for slot = 1, C.GetContainerNumSlots(bag) do
      local id = C.GetContainerItemID(bag, slot)
      local _stackCount = util:GetContainerStackCount(bag, slot)

      if id == itemID then
        return true, bag, slot
      end
    end
  end
  return false, nil, nil
end

---FindEmptyBagSlot function searches for an empty slot in the player's bags.
---It iterates through each bag and slot, checking if the slot is empty by
---retrieving the item ID. If an empty slot is found, it returns the bag and
---slot numbers. If no empty slot is found, it returns nil.
---This is used to split a stack of items if we need to sell less than the total stack.
---@return boolean hasEmpty
---@return number|nil bag
---@return number|nil slot
---@diagnostic disable-next-line: unused-function
_FindEmptyBagSlot = function ()
  for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
    for slot = 1, C.GetContainerNumSlots(bag) do
      local id = C.GetContainerItemID(bag, slot)
      if not id then
        return true, bag, slot
      end
    end
  end
  return false, nil, nil
end

local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class MerchantEvents: AceEvent, AceMessage
local merchEvents = addon:NewModule("MerchantEvents")

LibStub("AceEvent-3.0"):Embed(merchEvents)

local merchantEvents = {
  ["MERCHANT_SHOW"] = function () addon:SendMessage("merchant/Show") end,
  ["MERCHANT_CLOSED"] = function () addon:SendMessage("merchant/Closed") end
}

function merchEvents:OnInitialize()
  for k, v in pairs(merchantEvents) do
    merchEvents:RegisterEvent(k, v)
  end
end

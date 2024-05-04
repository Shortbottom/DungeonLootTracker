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

---@class Reports: AceModule, AceMessage
local reports = addon:NewModule("Reports")

LibStub("AceEvent-3.0"):Embed(reports)

local reportsMessages = {
  ["reports/Show"] = "reportsShow",
  ["reports/Close"] = "reportsClosed",
}

function reports:OnInitialize()
  for k, v in pairs(reportsMessages) do
    reports:RegisterMessage(k, v)
  end
end

function reports:reportsShow(_)
  addon:Print("35: Reports Show")
end

function reports:reportsClosed(_)
  addon:Print("39: Reports Closed")
end

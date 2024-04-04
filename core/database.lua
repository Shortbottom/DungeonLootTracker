local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local constants = addon:GetModule("Constants")


---@class Database: AceModule
---@field private data databaseOptions
local DB = addon:NewModule("Database")

function DB:OnInitialize()
  print("Initialise DB")
  addon.db = LibStub("AceDB-3.0"):New("dltDB", constants.DATABASE_DEFAULTS)
end

DB:Enable()

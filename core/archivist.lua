-- TODO: We could potentially end up with a LOT of data which will make loading it all take longer and longer.
-- TODO: So we want to add in the use of Archivist to compress the data and maybe segment it as well.

-- local addonName = ... ---@type string

-- ---@class DLT_Addon: AceAddon
-- local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

-- ---@class Constants: AceModule
-- local constants = addon:GetModule("Constants")

-- ---@class ShortyUtil: AceModule
-- local ShortyUtil = addon:GetModule("ShortyUtil")

-- ---@class DLT_Archivist: AceModule
-- local dlt_archivist = addon:NewModule("DLT_Archivist")

-- -- local Archivist = addon.Archivist

-- function dlt_archivist:OnInitialize()
--   dltRecordings_DB = dltRecordings_DB or { totalRecordings = 0, lastUsedID = 0, records = {} }
--   self.db = dltRecordings_DB

--   -- self.db.totalRecordings = 0
--   -- self.db.lastUsedID = 0
-- end

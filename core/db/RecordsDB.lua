local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Constants: AceModule
local constants = addon:GetModule("Constants")

---@class Database: AceModule
local db = addon:GetModule("Database")

---@class RecordsDB: AceModule
local recordsDB = addon:NewModule("RecordsDB")

function recordsDB:OnInitialize()
  DltRecordings_DB = DltRecordings_DB or { totalRecordings = 0, lastUsedID = 0, records = {} }
  recordsDB.data = DltRecordings_DB
end

---Returns the next ID to use
--- TODO: Perform checks on id and fix for any errors
---@return integer
function recordsDB:GetNewID()
  local id = recordsDB.data.lastUsedID
  return id + 1
end

---Save the new recording to the SV
---@param id number # The ID of the new record
---@param tbl table # The table to save
---@return boolean # If the save was successful
function recordsDB:SaveNewRecord(id, tbl)
  local success = false
  local totalRecordings = recordsDB.data.totalRecordings
  recordsDB.data.lastUsedID = id
  recordsDB.data.totalRecordings = totalRecordings + 1
  addon.currentRecID = id
  tinsert(recordsDB.data.records, tbl)
  return success
end

---Returns the index position of the provided id
---@param id number
---@return number
function recordsDB:GetIndex(id)
  for k, v in pairs(recordsDB.data.records) do
    if id == v.recordID then return k end
  end
  return 0
end

recordsDB:Enable()

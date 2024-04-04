local addonName = ... ---@type string

---@class DLT_Addon: AceAddon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@alias eventData any[][]

---@class Callback
---@field cb fun(...)
---@field a any
local callbackProto = {}

---@class Events: AceModule
local events = addon:NewModule("Events")

function events:OnInitialize()
  self._eventHandler = {}
  self._messageMap = {}
  self._eventMap = {}
  self._bucketTimers = {}
  self._eventQueue = {}
  self._bucketCallbacks = {}
  self._eventArguments = {}
  LibStub:GetLibrary("AceEvent-3.0"):Embed(self._eventHandler)
end

events:Enable()

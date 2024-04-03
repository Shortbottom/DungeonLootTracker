-- This contains all the functions that will be used within the Options-Minimap section
local addonName, DLT_Addon = ...
local DLT_Minimap = LibStub:NewLibrary("DLT_Minimap", 10)

if not DLT_Minimap then
  return
end

DLT_Minimap.embeds = DLT_Minimap.embeds or {}

DLT_Addon.MinimapBtnName = addonName .. "_Minimap"

local icon = LibStub("LibDBIcon-1.0")

function DLT_Minimap:LoadMinimapBtn()
  --- Setup the LDB Data Object for the minimap icon
  ---@type table
  local dltLDB =
      LibStub("LibDataBroker-1.1"):NewDataObject(
        addonName,
        {
          type = "data source",
          text = "Dungeon Loot Tracker",
          icon = "DungeonLootTracker\\Images\\icon.jpeg",
          OnClick = function (_, button)
            DLT_Addon.minimap_Click(_, button)
          end
        }
      )
end

-- Option Functions

-- CAUTION: LibDBIcon option to hide or show the minimap icon is a hide flag and we want to refer to it as a show flag
-- CAUTION: so when the user says to Show we need to store false in the settings table

function DLT_Minimap:GetShowMinimap()
  return not self.db.profile.minimap.hide
end

--- Show/Hide the minimap button. Library uses a hide flag, we use a show flag so swap it over <br>
--- e.g. If value is true we need to store false. False = user wants to show the button; True = user wants to hide the button
---@param value boolean
function DLT_Minimap:SetShowMinimap(value)
  print("dddd")
  if value then
    self.db.profile.minimap.hide = false
    icon:Show(self.MinimapBtnName)
  else
    self.db.profile.minimap.hide = true
    icon:Hide(self.MinimapBtnName)
  end
end

-- INFO: LibDBIcon's option to lock the minimap is a lock flag which matches with the user setting so no need to reverse it
---Store the setting for locking the position of the minimap button
---@param val boolean
function DLT_Minimap:SetLockMinimap(val)
  self.db.profile.minimap.lock = val
  if val then
    icon:Lock(self.Metadata.AddonName .. "_Minimap")
  else
    icon:Unlock(self.Metadata.AddonName .. "_Minimap")
  end
  self.RefreshConfig()
end

local mixins = {
  "LoadMinimapBtn",
  "GetShowMinimap",
  "SetShowMinimap",
  "SetLockMinimap"
}

-- Embeds AceConsole into the target object making the functions from the mixins list available on target:..
-- @param target target object to embed AceBucket in
function DLT_Minimap:Embed(target)
  for k, v in pairs(mixins) do
    target[v] = self[v]
  end
  self.embeds[target] = true
  return target
end

for addon in pairs(DLT_Minimap.embeds) do
  DLT_Minimap:Embed(addon)
end

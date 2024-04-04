local lib = LibStub:NewLibrary("Shorty_Util", 10)

if not lib then
  return
end

---@type string
local build = (GetBuildInfo())
---@type integer
local major = string.match(build, "(%d+)%.(%d+)%.(%d+)(%w?)")

---@type boolean
lib.IsWrathClassic = major == "3"
---@type boolean
lib.IsDragonflightRetail = major == "10"

-- NOTE: Should be able to get rid of this when I rewrite the text recoloring function
---Make a deep copy of a table
---@param src table
---@param dest table
function lib.DeepCopyTable(src, dest)
  for index, value in pairs(src) do
    if type(value) == "table" then
      dest[index] = {}
      lib.DeepCopyTable(value, dest[index])
    else
      dest[index] = value
    end
  end
end

---@class table
---@field Metadata table
lib.Metadata = {}
local metadata = lib.Metadata

---Get all the Metadata and store it locally in our Addon Namespace
---@param addonName string The Addon name as wow sees it
---@return table Return a table containing all the Metadata
function metadata.GetAddOnMetadata(addonName)
  local version = C_AddOns.GetAddOnMetadata(addonName, "Version")
  local title = C_AddOns.GetAddOnMetadata(addonName, "Title")       --addonName -- Name of the AddOn folder
  local acronym = C_AddOns.GetAddOnMetadata(addonName, "X-Acronym") -- Short abbreviation for the addonName
  local notes = C_AddOns.GetAddOnMetadata(addonName, "Notes")
  local icon = C_AddOns.GetAddOnMetadata(addonName, "IconTexture")  --"Interface\\Addons\\DungeonLootTracker\\Images\\icon"
  local author = C_AddOns.GetAddOnMetadata(addonName, "Author")
  local wago = C_AddOns.GetAddOnMetadata(addonName, "X-Wago-ID")
  local curse = C_AddOns.GetAddOnMetadata(addonName, "X-Curse-Project-ID")

  return {
    AddonName = addonName,
    Title = title,
    Version = version,
    Build = build,
    Acronym = acronym,
    Notes = notes,
    Icon = icon,
    Author = author,
    WAGO = wago,
    Curse = curse
  }
end

---Iterates through a table and prints its
---@param tbl table
function lib:tprint(tbl)
  for key, value in pairs(tbl) do
    print("key: ", key, "; value: ", value)
  end
end

local lib = LibStub:NewLibrary("Shorty_Util", 1)

if not lib then
  return
end

local version = (GetBuildInfo())
local major = string.match(version, "(%d+)%.(%d+)%.(%d+)(%w?)")
lib.IsWrathClassic = major == "3"
lib.IsDragonflightRetail = major == "10"

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

--[[
  -- Might end up coming back to this method, i'm not sure
  -- Embed my utilities

  local mixins = {
    "DeepCopyTable",
    "minimap_Click",
    "RefreshConfig"
  }

  function lib:Embed(target)
    for k, v in pairs(mixins) do
      target[v] = self[v]
    end
    self.embeds[target] = true
    return target
  end

  for addon in pairs(lib.embeds) do
    lib.Embed(addon)
  end
--]]

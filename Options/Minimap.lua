local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Database: AceModule
local DB = addon:GetModule("Database")

---@class Localisation: AceModule
local L = addon:GetModule("Localisation")

---@class Minimap: AceModule, LibDBIcon
local minimap = addon:GetModule("Minimap")

---@class Constants: AceModule
local const = addon:GetModule("Constants")

---@class MinimapOptions: AceModule
local minimapOptions = addon:NewModule("MinimapOptions")

function minimapOptions:GetMinimapOptions()
  local options = {
    handler = addon,
    type = "group",
    name = L:G("Minimap"),
    order = 2,
    args = {
      hide = {
        type = "toggle",
        name = "Hide Minimap Button",
        desc = "Show/Hide the Minimap Button.",
        order = 1,
        get = function () return DB:GetMinimapHide() end,
        set = function (_, enabled)
          DB:SetMinimapHide(enabled)
          if enabled then
            minimap:Hide()
          else
            minimap:Show()
          end
        end
      },
      lock = {
        type = "toggle",
        name = "Lock Minimap Button",
        desc = "Lock the position of the minimap button.",
        order = 2,
        get = function () return DB:GetMinimapLock() end,
        set = function (_, enabled)
          DB:SetMinimapLock(enabled)
          if enabled then
            minimap:Lock()
          else
            minimap:Unlock()
          end
        end
      },
      radius = {
        type = "range",
        name = "Button Position",
        desc = "Position of the button round the minimap",
        order = 3,
        min = 0,
        max = 360,
        step = 1,
        get = function () return DB:GetMinimapPos() end,
        set = function (_, value)
          DB:SetMinimapPos(value)
          minimapOptions.SetPosition()
        end
      },
      --[[ Not using til bugs are sorted out

        showInCompartment = {
          type = "toggle",
          name = "Show in Compartment",
          desc = "Show the button in the compartment",
          order = 4,
          hidden = true,
          get = function () return DB:GetMinimapCompartment() end,
          set = function (_, enabled)
            DB:SetMinimapCompartment(enabled)
            if enabled then
              minimapOptions:ShowInCompartment() -- Not done yet
            else
              minimapOptions:HideInCompartment() -- Not done yet
            end
          end
        }
        --]]
    }
  }
  return options
end

---Lock the minimap button
function minimapOptions:Lock()
  addon.minimapIcon:Lock(const.miniMapBtnName)
end

---Unlock the minimap button
function minimapOptions:Unlock()
  addon.minimapIcon:Unlock(const.miniMapBtnName)
end

---Show the minimap button
function minimapOptions:Show()
  addon.minimapIcon:Show(const.miniMapBtnName)
end

---Hide the minimap button
function minimapOptions:Hide()
  addon.minimapIcon:Hide(const.miniMapBtnName)
end

-- Doing this here because I think the function belongs in this section but the function needs to be on the AddOn namespace
function addon:DLT_OnAddonCompartmentClick()
  addon:Print("DLT_OnAddonCompartmentClick")
end

function minimapOptions:ShowInCompartment()

end

function minimapOptions:HideInCompartment()

end

function minimapOptions.SetPosition()
  addon.minimapIcon:Refresh(const.miniMapBtnName, DB:GetData().profile.minimap)
end

minimapOptions:Enable()

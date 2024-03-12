DLTAddOn = LibStub("AceAddon-3.0"):NewAddon("DLTAddOn", "AceConsole-3.0")
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceGUI = LibStub("AceGUI-3.0")

local appName = "Dungeon Loot Tracker"
local windowShown = false

local defaults = {
    profile = {
        toggleOption = true,
        playerName = "",
        msg = "",
        subOptions = {
            subOptA = false,
            subOptB = true
        }
    }
}

local DLTOptions = {
    name = appName,
    handler = DLTAddOn,
    type = "group",
    args = {
        toggleOption = {
            name = "Toggle Option",
            desc = "Toggle Option On/Off",
            type = "toggle",
            set = "SetToggleOption",
            get = function(info) return DLTAddOn.db.profile.toggleOption end,
        },
        msg = {
            name = "Welcome Message",
            desc = "The message to welcome you to the game",
            type = "input",
            set = "SetMyMessage",
            get = "GetMyMessage"
        }
    }
}

AceConfig:RegisterOptionsTable(appName .. " Options", DLTOptions)
AceConfigRegistry:RegisterOptionsTable(appName .. " Options", DLTOptions, true)

function DLTAddOn:OnInitialize()
    -- Code that runs when first loaded - i.e restore settings
    DLTAddOn:Print(appName, ": OnInitialize")
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(appName .. " Options", appName, nil)
    self.db = LibStub("AceDB-3.0"):New("dltDB", defaults)
    self.db.profile.playerName = GetUnitName("player")
    self:RegisterChatCommand("dlt", "toggleWindow")

    DLTAddOn:createMainWindow()
end

function DLTAddOn:OnEnable()
    -- Code that runs when the AddOn is enabled
    DLTAddOn:Print("Enabling AddOn")
    DLTAddOn:Enable()
end

function DLTAddOn:OnDisable()
    -- Code that runs when the AddOn is disabled
    DLTAddOn:Print("Disabling AddOn")
    DLTAddOn:Disable()
end

function DLTAddOn:GetMyMessage(info)
    return self.db.profile.msg
end

function DLTAddOn:SetMyMessage(info, input)
    self.db.profile.msg = input
    DLTAddOn:Print(self.db.profile.msg)
end

-- Option Functions

function DLTAddOn:SetToggleOption(info, val)
    self.db.profile.toggleOption = val
    AceConfigRegistry:NotifyChange(appName)
end

function DLTAddOn:openOptions(input)
    InterfaceOptionsFrame_OpenToCategory(appName .. " Options")
end
`
function DLTAddOn:toggleWindow(input)
    if windowShown then
        AceConfigDialog:Close(appName .. " Options")
    else
        AceConfigDialog:Open(appName .. " Options")
    end
end

-- Create the GUI Windows

function DLTAddOn:createMainWindow()
    -- Create the Main Window Frame
    local f = AceGUI:Create("Window")
    f:SetCallback("OnClose", function(widget)
        windowShown = false
        AceGUI:Release(widget)
    end)
    f:SetTitle(appName)
    f:SetStatusText("Status Bar")
    f:SetLayout("Flow")
    f:SetWidth(150)

    -- Create a button
    local btn = AceGUI:Create("Button")
    btn:SetWidth(100)
    btn:SetText("Button")
    btn:SetCallback("OnClick", function() print("You clicked me!") end)
    f:AddChild(btn)

    windowShown = true
end

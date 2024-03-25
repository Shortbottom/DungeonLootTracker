local addonName, addon = ...
addon.Util.Colors = {}
local colors = addon.Util.Colors

colors.AllianceBlueRGB = { R = 0.290, G = 0.329, B = 0.910, A = 1.000 } -- "|cff4a54e8" PLAYER_FACTION_COLOR_ALLIANCE
colors.HordeRedRGB = { R = 0.898, G = 0.051, B = 0.071, A = 1.000 }     -- "|cffe50d12" PLAYER_FACTION_COLOR_HORDE

function colors.SetTextColor(text, color)
    return string.format(color, text)
end

function colors.RemoveColor(text)
    text = string.gsub(text or "",
        "|c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]", "");
    text = string.gsub(text or "", "|r", "");
    return text;
end

function colors.RGBPrct2HEX(r, g, b, a)
    if type(r) == "table" then
        -- When only r is provided, g can act as the alpha value if r only contains rgb
        a = r.A == nil and (g == nil and 1 or g) or r.A;
        b = r.B;
        g = r.G;
        r = r.R;
    end
    local hex = "";
    for _, v in next, { a, r, g, b } do
        local h = string.format("%02x", math.floor(v * 255));
        hex = hex .. h;
    end
    return hex;
end

-- Adding functions dynamically to string
local tmpColors = {};
for colorName, color in next, colors do
    if string.find(colorName, "RGB") and type(color) == "table" then
        color.Hex = colors.RGBPrct2HEX(color);
        tmpColors[colorName:sub(1, -4)] = "|c" .. color.Hex .. "%s|r";
        string["SetColor" .. colorName:sub(1, -4)] = function(self)
            return colors.SetTextColor(self, colors[colorName:sub(1, -4)]);
        end
    end
end

addon.Util.DeepCopyTable(tmpColors, colors);
tmpColors = nil;

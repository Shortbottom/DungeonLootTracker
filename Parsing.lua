local _, addon = ...

function addon.ItemKey(link)
    local key = link and (link:match("|H(item:[^|]+)|h") or link:match("^(item:[^|]+)$"))
    if not key then return end
    local fields = {}
    for field in (key .. ":"):gmatch("(.-):") do fields[#fields + 1] = field end
    -- item:ID:...:context:bonusCount:bonusIDs:modifierCount:type:value:...
    -- The same modifier pairs can be serialized in different orders by chat and bags.
    local bonusCount = tonumber(fields[14])
    if not bonusCount or bonusCount < 0 or bonusCount % 1 ~= 0 then return key end
    local countIndex = 15 + bonusCount
    local modifierCount = tonumber(fields[countIndex])
    if not modifierCount or modifierCount < 2 or modifierCount % 1 ~= 0
        or countIndex + modifierCount * 2 > #fields then return key end
    local modifiers = {}
    for index = 1, modifierCount do
        local offset = countIndex + (index - 1) * 2
        modifiers[index] = { fields[offset + 1], fields[offset + 2] }
    end
    table.sort(modifiers, function(a, b)
        return a[1] == b[1] and a[2] < b[2] or a[1] ~= b[1] and a[1] < b[1]
    end)
    for index, modifier in ipairs(modifiers) do
        local offset = countIndex + (index - 1) * 2
        fields[offset + 1], fields[offset + 2] = modifier[1], modifier[2]
    end
    return table.concat(fields, ":")
end

-- Match Blizzard's localized printf strings, including positional arguments.
function addon.MatchFormat(text, format)
    if not format then return end
    local pattern, arguments, index, nextArgument = "", {}, 1, 1
    while index <= #format do
        local tail = format:sub(index)
        local token, position, kind = tail:match("^(%%(%d+)%$([sd]))")
        if not token then token, kind = tail:match("^(%%([sd]))") end
        if token then
            arguments[#arguments + 1] = tonumber(position) or nextArgument
            nextArgument = nextArgument + 1
            pattern = pattern .. (kind == "d" and "([%d%.,%s]+)" or "(.-)")
            index = index + #token
        else
            local char = format:sub(index, index)
            pattern = pattern .. char:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            index = index + 1
        end
    end
    local captures = { text:match("^" .. pattern .. "$") }
    if #captures == 0 then return end
    local result = {}
    for i, argument in ipairs(arguments) do result[argument] = captures[i] end
    return result
end

function addon.ParseLoot(message)
    for _, name in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF" }) do
        local values = addon.MatchFormat(message, _G[name])
        if values then return values[1], tonumber(values[2]) or 1 end
    end
end

function addon.ParseMoney(message)
    local money
    for _, name in ipairs({ "YOU_LOOT_MONEY_GUILD", "LOOT_MONEY_SPLIT_GUILD", "YOU_LOOT_MONEY", "LOOT_MONEY_SPLIT" }) do
        local values = addon.MatchFormat(message, _G[name])
        if values then money = values[1]; break end
    end
    if not money then return end
    local total, found = 0, false
    for _, coin in ipairs({ { GOLD_AMOUNT, 10000 }, { SILVER_AMOUNT, 100 }, { COPPER_AMOUNT, 1 } }) do
        if coin[1] then
            local suffix = coin[1]:gsub("%%d", ""):gsub("%%1%$d", "")
            suffix = suffix:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
            local value = money:match("([%d%.,%s\194\160\226\128\175]+)" .. suffix)
            if value then total = total + tonumber((value:gsub("%D", ""))) * coin[2]; found = true end
        end
    end
    return found and total or nil
end

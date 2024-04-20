local addonName = ... ---@type string

---@class Addon
local addon = LibStub("AceAddon-3.0"):GetAddon(addonName)

---@class Locales: AceModule
local L = LibStub("AceLocale-3.0"):GetLocale(addonName)

---@class ShortyUtil: AceModule
local util = addon:NewModule("ShortyUtil")

--- Deep copy a Lua table.<br>
--- Recursively copies all the elements of a table into a new table.
--- @param src table source table to be copied.
--- @param dest table destination table to store the copied elements.
function util.DeepCopyTable(src, dest)
  for index, value in pairs(src) do
    if type(value) == "table" then
      dest[index] = {}
      util.DeepCopyTable(value, dest[index])
    else
      dest[index] = value
    end
  end
end

--- Prints a table with an optional prefix string.
--- @param tbl table The table to print.
--- @param pre_fix string # prefix string.
function util:tprint(tbl, pre_fix)
  pre_fix = pre_fix or ""
  print(util:table_to_json(tbl))
  local _tbl = util:TableToString(tbl)
  _tbl = string.gsub(_tbl, "{ { ", "\n{\n " .. fastrandom() .. " {\n    "):gsub(" }, ", "\n  },\n  "):gsub(" }", "\n  }\n}"):gsub(", ", ",\n   ")
  print(pre_fix, _tbl)
end

---Converts a table to a string representation.
---The function takes a table and a variable number of additional arguments that control the output format.
---The additional arguments can be used to set the maximum line length, the initial indentation level, and whether to print hash keys and handle tags.
---The function uses several helper functions to generate the string representation, including functions to accumulate parts of the string, check if a string is a valid identifier, and calculate the length of a string representation of a value.
---The function handles different types of values, and applies the configuration options for printing hash keys and handling tags.
---@param t table table to convert to a string.
---@param ... string additional arguments that control the output format.
---@return string str representing the table.
function util:TableToString(t, ...)
  local PRINT_HASH = true
  local HANDLE_TAG = true
  local FIX_INDENT, LINE_MAX, INITIAL_INDENT

  for _, x in ipairs { ... } do
    if type(x) == "number" then
      if not LINE_MAX then
        LINE_MAX = x
      else
        INITIAL_INDENT = x
      end
    elseif x == "nohash" then
      PRINT_HASH = false
    elseif x == "notag" then
      HANDLE_TAG = false
    else
      local n = string.match(x, "^indent%s*(%d*)$")
      if n then
        FIX_INDENT = tonumber(n) or 3
      end
    end
  end

  LINE_MAX = LINE_MAX or math.huge
  INITIAL_INDENT = INITIAL_INDENT or 1

  local current_offset = 0 -- indentation level
  local xlen_cache = {}    -- cached results for xlen()
  local acc_list = {}      -- Generated bits of string

  local function acc(...)  -- Accumulate a bit of string
    local x = table.concat { ... }
    current_offset = current_offset + #x
    table.insert(acc_list, x)
  end

  local function valid_id(x)
    return type(x) == "string" and string.match(x, "^[a-zA-Z_][a-zA-Z0-9_]*$")
  end

  local function xlen(x, nested)
    nested = nested or {}

    if x == nil then
      return #"nil"
    end

    local len = xlen_cache[x]

    if len then
      return len
    end

    local f = xlen_type[type(x)]

    if not f then
      return #tostring(x)
    end

    len = f(x, nested)
    xlen_cache[x] = len
    return len
  end

  if LINE_MAX == math.huge then
    xlen = function ()
      return 0
    end
  end

  xlen_type = {
    ["nil"] = function ()
      return 3
    end,
    ["number"] = function (x)
      return #tostring(x)
    end,
    ["boolean"] = function (x)
      return x and 4 or 5
    end,
    ["string"] = function (x)
      return #string.format("%q", x)
    end,
    ["table"] = function (adt, nested)
      if nested[adt] then
        return #tostring(adt)
      end

      nested[adt] = true
      local has_tag = HANDLE_TAG and valid_id(adt.tag)
      local alen = #adt
      local has_arr = alen > 0
      local has_hash = false
      local x = 0

      if PRINT_HASH then
        for k, v in pairs(adt) do
          if k == "tag" and has_tag then
          elseif type(k) == "number" and k <= alen and math.fmod(k, 1) == 0 then
          else
            has_hash = true

            if valid_id(k) then
              x = x + #k
            else
              x = x + xlen(k, nested) + 2
            end

            x = x + xlen(v, nested) + 5
          end
        end
      end

      for i = 1, alen do
        x = x + xlen(adt[i], nested) + 2
      end

      nested[adt] = false

      if not (has_tag or has_arr or has_hash) then
        return 3
      end

      if has_tag then
        x = x + #adt.tag + 1
      end

      if not (has_arr or has_hash) then
        return x
      end

      if not has_hash and alen == 1 and type(adt[1]) ~= "table" then
        return x - 2
      end

      return x + 2
    end
  }

  local function rec(adt, nested, indent)
    if not FIX_INDENT then
      indent = current_offset
    end

    local function acc_newline()
      acc("\n")
      acc(string.rep(" ", indent))
      current_offset = indent
    end

    local function acc_string(s)
      acc((string.format("%q", s):gsub("\\\n", "\\n")))
    end

    local function acc_table()
      if nested[adt] then
        acc(tostring(adt))
        return
      end

      nested[adt] = true
      local has_tag = HANDLE_TAG and valid_id(adt.tag)
      local alen = #adt
      local has_arr = alen > 0
      local has_hash = false

      if has_tag then
        acc("`")
        acc(adt.tag)
      end

      if PRINT_HASH then
        for k, v in pairs(adt) do
          if not (k == "tag" and HANDLE_TAG) and not (type(k) == "number" and k <= alen and math.fmod(k, 1) == 0) then
            if not has_hash then
              acc("{ ")

              if not FIX_INDENT then
                indent = current_offset
              end
            else
              acc(", ")
            end

            local is_id, expected_len = valid_id(k)

            if is_id then
              expected_len = #k + xlen(v, nested) + #" = , "
            else
              expected_len = xlen(k, nested) + xlen(v, nested) + #"[] = , "
            end

            if has_hash and expected_len + current_offset > LINE_MAX then
              acc_newline()
            end

            if is_id then
              acc(k)
              acc(" = ")
            else
              acc("[")
              rec(k, nested, indent + (FIX_INDENT or 0))
              acc("] = ")
            end

            rec(v, nested, indent + (FIX_INDENT or 0))
            has_hash = true
          end
        end
      end

      if not has_tag and not has_hash and not has_arr then
        acc("{ }")
      elseif has_tag and not has_hash and not has_arr then
      else
        assert(has_hash or has_arr)

        local no_brace = false

        if has_hash and has_arr then
          acc(", ")
        elseif has_tag and not has_hash and alen == 1 and type(adt[1]) ~= "table" then
          acc(" ")
          rec(adt[1], nested, indent + (FIX_INDENT or 0))
          no_brace = true
        elseif not has_hash then
          acc("{ ")

          if not FIX_INDENT then
            indent = current_offset
          end
        end

        if not no_brace and has_arr then
          rec(adt[1], nested, indent + (FIX_INDENT or 0))

          for i = 2, alen do
            acc(", ")

            if current_offset + xlen(adt[i], {}) > LINE_MAX then
              acc_newline()
            end

            rec(adt[i], nested, indent + (FIX_INDENT or 0))
          end
        end

        if not no_brace then
          acc(" }")
        end
      end

      nested[adt] = false
    end

    local function acc_default(x)
      acc(tostring(x))
    end

    local x = {
      ["nil"] = function ()
        acc("nil")
      end,
      ["number"] = function ()
        acc(tostring(adt))
      end,
      ["string"] = function ()
        acc_string(adt)
      end,
      ["boolean"] = function ()
        acc(adt and "true" or "false")
      end,
      ["table"] = function ()
        acc_table()
      end
    }

    local y = x[type(adt)]

    if y then
      y()
    else
      acc_default(adt)
    end
  end

  current_offset = INITIAL_INDENT or 0
  rec(t, {}, 0)
  return table.concat(acc_list)
end

---Converts a given number of seconds to a readable format.
---The format is in the form of "HH.MM.SS", where HH represents hours, MM represents minutes, and SS represents seconds.
---@param diff number number of seconds to convert.
---@return string str string representing the given number of seconds.
function util:convertSecsToReadable(diff)
  return string.format("%02d.%02d.%02d", math.floor(diff / 3600), math.floor((diff % 3600) / 60), diff % 60)
end

--- Converts a Lua table to a JSON string.
---@param tbl table The Lua table to be converted.
---@param label? string Additional arguments to control the output format.
---@return string JSON String representation of the table.
function util:table_to_json(tbl, label)
  local json_str = ""
  ---@diagnostic disable-next-line: redefined-local
  local function serialize(tbl)
    local comma = false
    local t = type(tbl)
    if t == "number" then
      json_str = json_str .. tbl
    elseif t == "boolean" then
      json_str = json_str .. (tbl and "true" or "false")
    elseif t == "string" then
      json_str = json_str .. string.format("%q", tbl):gsub("\n", ""):gsub("\\", " ")
    elseif t == "table" then
      json_str = json_str .. "{"
      for k, v in pairs(tbl) do
        if comma then
          json_str = json_str .. ","
        end
        json_str = json_str .. "\"" .. k .. "\":"
        serialize(v)
        comma = true
      end
      json_str = json_str .. "}"
    else
      error("Unsupported data type: " .. t)
    end
  end

  serialize(tbl)
  if label then
    json_str = "\n//" .. label .. "\n" .. json_str .. "\n"
  end
  return json_str
end

---@deprecated
function util:print(...)
  print("|cFF18b566DLT: |r", ...)
end

---Takes a string that can contain any number of money values including line breaks in the form of "X Gold Y Silver Z Copper"
---and converts it to a string in the form of "X.Y.Z". WoW stores the player money if the form of 000000
---@param arg string money value to convert.
---@return number number representation of the money value.
function util:convertMoneyToString(arg)
  -- Tables to store possible labels for each metal in different languages
  local labels = {
    Gold = { L["Gold"] },
    Silver = { L["Silver"] },
    Copper = { L["Copper"] }
  }

  -- Function to find the metal type based on the label
  local function findMetalType(label)
    for metal, translations in pairs(labels) do
      for _, translation in ipairs(translations) do
        if label == translation then
          return metal
        end
      end
    end
    return nil
  end

  -- Table to store the extracted numbers with labels
  local amounts = {}

  -- Pattern to match numbers followed by their labels
  local pattern = "(%d+)%s*(%a+)"

  -- Function to extract numbers and their labels
  for number, label in string.gmatch(arg, pattern) do
    local metalType = findMetalType(label)
    if metalType then
      amounts[metalType] = tonumber(number)
    end
  end

  -- Accessing the values by their labels
  local gold = amounts[L["Gold"]] or 0
  local silver = amounts[L["Silver"]] or 0
  local copper = amounts[L["Copper"]] or 0
  return tonumber(gold .. silver .. copper) or 0
end

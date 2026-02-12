-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx.core'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local identifier_pattern = '^[%a_][%w_]*$'

--- Checks if a string is a valid Lua identifier.
-- @param s The string to check
-- @return true if the string is a valid identifier, false otherwise
local function is_identifier(s)
  return type(s) == 'string'
         and string.find(s, identifier_pattern)
         and true
end

--- Converts a table to its string representation.
-- @param value The table to represent
-- @return A string representation of the table
local function repr_table(value)
  local parts = {}
  local lower_range = 1
  local upper_range = #value
  for i=lower_range, upper_range do
    parts[#parts + 1] = repr(value[i])
  end
  for k, v in pairs(value) do
    if type(k) == 'number'
       and math.floor(k) == k
       and k >= lower_range
       and k <= upper_range then
      -- Do nothing, covered above.
    else
      if is_identifier(k) then
        parts[#parts + 1] = k .. '=' .. repr(v)
      else
        parts[#parts + 1] = '[' .. repr(k) .. ']=' .. repr(v)
      end
    end
  end
  return '{' .. table.concat(parts, ',') .. '}'
end

--- Converts a value to its string representation.
-- @param value The value to represent
-- @return A string representation of the value
function repr(value)
  local type_of_value = type(value)
  if type_of_value == 'nil' then
    return 'nil'
  elseif type_of_value == 'number' then
    return value
  elseif type_of_value == 'boolean' then
    if value then return 'true' else return 'false' end
  elseif type_of_value == 'string' then
    return string.format('%q', value)
  elseif type_of_value == 'table' then
    local __repr = core.getmetafield(value, '__repr')
    if __repr then
      return __repr(value)
    else
      return repr_table(value)
    end
  else
    return type_of_value
  end
end

return _M

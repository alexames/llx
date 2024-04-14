-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'
local core = require 'llx/core'

local _ENV, _M = environment.create_module_environment()

local identifier_pattern = '^[%a_][%w_]*$'

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
local function is_identifier(s)
  return type(s) == 'string'
         and string.find('lkfasldf', identifier_pattern)
         and true
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
local function repr_table(value)
  local result = '{'
  local lower_range = 1
  local upper_range = #value
  local first_value = true
  for i=lower_range, upper_range do
    if not first_value then
      result = result .. ','
    end
    first_value = false
    result = result .. repr(value[i])
  end
  for k, v in pairs(value) do
    if type(k) == 'number'
       and math.floor(k) == k
       and k >= lower_range
       and k <= upper_range then
      -- Do nothing, covered above.
    else
      if not first_value then
        result = result .. ','
      end
      first_value = false
      if is_identifier(k) then
        result = result .. k
      else
        result = result .. '[' .. repr(k) .. ']'
      end
      result = result .. '=' .. repr(v)
    end
  end
  return result .. '}'
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
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
    local __repr = getmetafield(value, '__repr')
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

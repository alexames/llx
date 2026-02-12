-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx.core'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local getmetafield = core.getmetafield

local FNV_offset_basis = 0x811c9dc5
local FNV_prime = 0x01000193

function hash_integer(value, hash)
  hash = hash ~ value
  hash = hash * FNV_prime
  hash = hash & 0xFFFFFFFF
  return hash
end

function hash_nil(value, hash)
  return hash
end

function hash_boolean(value, hash)
  return hash_integer(value and 1 or 0, hash)
end

function hash_number(value, hash)
  if value % 1 == 0 then
    return hash_integer(value, hash)
  end
  local bytes = string.pack('d', value)
  return hash_string(bytes, hash)
end

function hash_string(value, hash)
  for i=1, #value do
    hash = hash_integer(value:byte(i), hash)
  end
  return hash
end

local function extend_list(a, b)
  for i, v in ipairs(b) do
    table.insert(a, v)
  end
end

local function get_ordered_keys(value)
  local boolean_keys, number_keys, string_keys, table_keys = {}, {}, {}, {}
  for k, _ in pairs(value) do
    local key_type = type(k)
    if key_type =='boolean' then
      table.insert(boolean_keys, k)
    elseif key_type =='number' then
      table.insert(number_keys, k)
    elseif key_type =='string' then
      table.insert(string_keys, k)
    elseif key_type =='table' then
      table.insert(table_keys, k)
    else
      error(string.format('type %s not supported', key_type))
    end
  end
  table.sort(boolean_keys)
  table.sort(number_keys)
  table.sort(string_keys)
  table.sort(table_keys, function(a, b) return tostring(a) < tostring(b) end)

  local result = boolean_keys
  extend_list(result, number_keys)
  extend_list(result, string_keys)
  extend_list(result, table_keys)
  return result
end

function hash_table(value, hash)
  local keys = get_ordered_keys(value)
  for _, k in ipairs(keys) do
    hash = hash_value(k, hash)
    hash = hash_value(value[k], hash)
  end
  return hash
end

local function hash_error(value, hash)
  -- TODO: error with Exception
  error(string.format('type %s not supported', type(value)))
end

local hash_functions = {
  ['nil']=hash_nil,
  ['boolean']=hash_boolean,
  ['number']=hash_number,
  ['string']=hash_string,
  ['table']=hash_table,

  ['function']=hash_error,
  ['userdata']=hash_error,
  ['thread']=hash_error,
}

function hash_value(value, hash)
  local value_type = type(value)
  local type_name = getmetafield(value, '__name') or value_type
  local hash_function = getmetafield(value, '__hash')
  if type(hash_function) ~= 'function' then
    hash_function = hash_functions[value_type]
  end
  hash = hash_string(type_name, hash)
  return hash_function(value, hash)
end

function hash(value)
  return hash_value(value, FNV_offset_basis)
end

return _M

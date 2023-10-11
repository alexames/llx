local FNV_offset_basis = 0x811c9dc5
local FNV_prime = 0x01000193

local function hash_integer(hash, byte)
  hash = hash ^ byte
  hash = hash * FNV_prime
  hash = hash & 0xFFFFFFFF
  return hash
end

local function hash_nil(hash)
  return hash
end

local function hash_boolean(hash, value)
  return hash_integer(hash, value and 1 or 0)
end

local function hash_number(hash, value)
  return hash_integer(hash, value)
end

local function hash_string(hash, value)
  for i=1, #value do
    hash = hash_integer(hash, value:sub(i,i):byte())
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
  table.sort(table_keys)

  local result = boolean_keys
  extend_list(result, number_keys)
  extend_list(result, string_keys)
  extend_list(result, table_keys)
  return result
end

local hash_value

local function hash_table(hash, value)
  local keys = get_ordered_keys(value)
  for _, k in ipairs(keys) do
    hash = hash_value(hash, k)
    hash = hash_value(hash, value[k])
  end
  return hash
end

local function hash_error(hash, value)
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

function hash_value(hash, value)
  local value_type = type(value)
  local hash_fn = hash_functions[value_type]
  local hash = hash_string(hash, value_type)
  return hash_fn(hash, value)
end

local function getmetamethod(value, methodname)
  local mt = getmetatable(methodname)
  return mt and rawget(mt, methodname)
end

local function fnv1a(value)
  local hash = getmetamethod(value, '__hash')
  if type(hash) == 'function' then
    return hash(value)
  end
  return hash or hash_value(FNV_offset_basis, value)
end

return fnv1a

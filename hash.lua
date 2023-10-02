local bit = require 'numberlua'

----[[
--------------------------------------------------------------------------------

function extend(a, b)
  for i, v in ipairs(b) do
    table.insert(a, v)
  end
end

function p(s)
  print(debug.getinfo(2).currentline, s)
  return s
end


--------------------------------------------------------------------------------

FNV_offset_basis = 0x811c9dc5
FNV_prime = 0x01000193

print(string.format('>>> 0x%X', FNV_offset_basis))
print(string.format('>>> 0x%X', FNV_prime))

function hash_byte(hash, byte)
  hash = bit.bit32.bxor(hash, byte)
  hash = hash * FNV_prime
  hash = bit.bit32.band(hash, 0xFFFFFFFF)
end

function hash_nil(hash)
  p(hash)
  return hash
end

function hash_boolean(hash, value)
  return hash_byte(hash, value and 1 or 0)
end

function hash_number(hash, value)
  return hash_string(hash, tostring(value))
end

function hash_string(hash, value)
  for i=1, #value do
    hash = hash_byte(hash, value:sub(i,i):byte())
  end
  return hash
end

function get_ordered_keys(value)
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
  extend(result, number_keys)
  extend(result, string_keys)
  extend(result, table_keys)
  return result
end

function hash_table(hash, value)
  local keys = get_ordered_keys(value)
  for _, k in ipairs(keys) do
    hash = hash_type(hash, k)
    hash = hash_type(hash, value[k])
  end
  return hash
end

function hash_error(hash, value)
  error(string.format('type %s not supported', type(value)))
end

local hash_functions = {
  ['nil']=hash_nil,
  boolean=hash_boolean,
  number=hash_number,
  string=hash_string,
  table=hash_table,

  ['function']=hash_error,
  ['userdata']=hash_error,
  ['thread']=hash_error,
}

function hash_type(hash, value)
  local value_type = type(value)
  local hash_fn = hash_functions[value_type]
  local hash = hash_string(hash, value_type)
  return hash_fn(hash, value)
end

function fnv1a(value)
  p(value)
  return hash_type(FNV_offset_basis, value)
end

print(string.format("0x%X", fnv1a(nil)))
print(string.format("0x%X", fnv1a({b=2,c=3,a=1})))

return { hash=fnv1a }
--]]
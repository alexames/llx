--------------------------------------------------------------------------------
-- ugh I hate it
-- https://stackoverflow.com/a/32389020/63791

local OR, XOR, AND = 1, 3, 4
function bitoper(a, b, oper)
  local r, m, s = 0, 2^7
  repeat
    s,a,b = a+b+m, a%m, b%m
    r,m = r + m*oper%(s-a-b), m/2
  until m < 1
  return r%256
end

local bit8 = {
  band = function(a, b) return bitoper(a, b, AND) end,
  bor  = function(a, b) return bitoper(a, b, OR) end,
  bxor = function(a, b) return bitoper(a, b, XOR) end,
}

--------------------------------------------------------------------------------

function extend(a, b)
  for i, v in ipairs(b) do
    table.insert(a, v)
  end
end

--------------------------------------------------------------------------------

FNV_offset_basis = 0xcbf29ce484222325
FNV_prime = 0x100000001b3

function hash_byte(hash, byte)
  return bit8.bxor(hash, byte) * FNV_prime
end

function hash_nil(hash, value)
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
  return hash_type(FNV_offset_basis, value)
end

return { hash=fnv1a }

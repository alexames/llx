-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Pure-Lua implementations of the operations llx.compat provides, for
-- the Lua versions that have no native form of them.
--
-- This file must parse and run on every supported Lua and reach no
-- version-specific name: the layers in llx.compat start from it and
-- override what their version does natively. Integer arguments are
-- whole numbers held in doubles, and every bitwise result is an
-- unsigned 32-bit value.
--
-- @module llx.compat.portable

local floor = math.floor

local TWO_32 = 4294967296
local TWO_16 = 65536

local M = {}

--- Width, in bits, of the integers the bitwise operations work on.
M.integer_bits = 32

--- Whether numbers carry a separate integer subtype (`3` vs `3.0`).
M.has_integer_subtype = false

--- Reads a global that the host may have left out, answering nil where
-- the global table raises for a missing name rather than answering nil.
--
-- Not `rawget(_G, name)`: a host that locks its global table can make
-- `_G` an empty proxy that reads the globals through from a table
-- beneath it, and rawget on the proxy finds none of them.
-- @param read A function written `function() return name end` in the
--   chunk whose globals are read, so that the read resolves `name`
--   against that chunk's environment.
-- @return The global's value, or nil when it is absent or reading it
--   raised.
function M.optional_global(read)
  local ok, value = pcall(read)
  if ok then return value end
  return nil
end

--- The debug library, or nil when the host did not open it, as a
-- sandbox usually does not.
--
-- What llx.compat reads through it degrades without it: metatables are
-- read with getmetatable, which answers a `__metatable` field in place
-- of the real metatable, so the compat `pairs`, `len` and `equals`
-- cannot see the metamethods of a value whose metatable is protected.
local debug_library = M.optional_global(function() return debug end)
if type(debug_library) ~= 'table' then debug_library = nil end
M.debug_library = debug_library

--- The metatable of a value, read past a `__metatable` field where the
-- debug library is available.
--
-- Without it this is getmetatable, which answers the `__metatable`
-- field of a protected metatable instead (see `debug_library`).
-- @param value Any value.
-- @return The value's metatable, or nil when it has none.
M.raw_getmetatable = debug_library and debug_library.getmetatable
    or getmetatable

-- Builds a bitwise operator that works four bits at a time from a
-- 16 x 16 table of nibble results, so a 32-bit operation takes eight
-- table lookups rather than thirty-two bit tests.
local function nibble_operator(bit_rule)
  local results = {}
  for a = 0, 15 do
    for b = 0, 15 do
      local value, place = 0, 1
      for _ = 1, 4 do
        local a_bit, b_bit = a % (place * 2) >= place, b % (place * 2) >= place
        if bit_rule(a_bit, b_bit) then
          value = value + place
        end
        place = place * 2
      end
      results[a * 16 + b] = value
    end
  end
  return function(a, b)
    a, b = a % TWO_32, b % TWO_32
    local value, place = 0, 1
    for _ = 1, 8 do
      local a_nibble, b_nibble = a % 16, b % 16
      value = value + results[a_nibble * 16 + b_nibble] * place
      a, b = (a - a_nibble) / 16, (b - b_nibble) / 16
      place = place * 16
    end
    return value
  end
end

--- Bitwise and of two integers.
-- @param a An integer; reduced modulo 2^32.
-- @param b An integer; reduced modulo 2^32.
-- @return The unsigned 32-bit result.
M.band = nibble_operator(function(a, b) return a and b end)

--- Bitwise or of two integers.
-- @param a An integer; reduced modulo 2^32.
-- @param b An integer; reduced modulo 2^32.
-- @return The unsigned 32-bit result.
M.bor = nibble_operator(function(a, b) return a or b end)

--- Bitwise exclusive or of two integers.
-- @param a An integer; reduced modulo 2^32.
-- @param b An integer; reduced modulo 2^32.
-- @return The unsigned 32-bit result.
M.bxor = nibble_operator(function(a, b) return a ~= b end)

--- Bitwise not of an integer.
-- @param a An integer; reduced modulo 2^32.
-- @return The unsigned 32-bit result.
function M.bnot(a)
  return TWO_32 - 1 - a % TWO_32
end

--- Shifts an integer left; a negative count shifts right.
-- @param a An integer; reduced modulo 2^32.
-- @param n The shift count. A count of 32 or more yields 0.
-- @return The unsigned 32-bit result.
function M.lshift(a, n)
  if n < 0 then return M.rshift(a, -n) end
  if n >= 32 then return 0 end
  return a % TWO_32 * 2 ^ n % TWO_32
end

--- Shifts an integer right, filling with zeros; a negative count
-- shifts left.
-- @param a An integer; reduced modulo 2^32.
-- @param n The shift count. A count of 32 or more yields 0.
-- @return The unsigned 32-bit result.
function M.rshift(a, n)
  if n < 0 then return M.lshift(a, -n) end
  if n >= 32 then return 0 end
  return floor(a % TWO_32 / 2 ^ n)
end

--- Floor division, as the `//` operator computes it.
-- @param a The dividend.
-- @param b The divisor.
-- @return The largest integer not greater than a / b.
function M.floordiv(a, b)
  return floor(a / b)
end

--- The low 32 bits of the product of two unsigned 32-bit integers,
-- exact even where the full product needs more than the 53 bits a
-- double holds.
-- @param a An integer in [0, 2^32).
-- @param b An integer in [0, 2^32).
-- @return (a * b) mod 2^32.
function M.u32_mul(a, b)
  local a_low, b_low = a % TWO_16, b % TWO_16
  local a_high, b_high = (a - a_low) / TWO_16, (b - b_low) / TWO_16
  local cross = (a_high * b_low + a_low * b_high) % TWO_16
  return (cross * TWO_16 + a_low * b_low) % TWO_32
end

local raw_getmetatable = M.raw_getmetatable

--- Compares two values with `==` as Lua 5.3+ does: when they are
-- tables (or both userdata) and not the same object, the __eq of
-- either operand decides. Lua 5.1 and 5.2 consult __eq only when both
-- operands carry the same one.
-- @param a Any value.
-- @param b Any value.
-- @return Whether a == b under Lua 5.3 rules.
function M.equals(a, b)
  if rawequal(a, b) then return true end
  local a_type, b_type = type(a), type(b)
  if a_type ~= b_type or (a_type ~= 'table' and a_type ~= 'userdata') then
    return false
  end
  local a_metatable, b_metatable = raw_getmetatable(a), raw_getmetatable(b)
  local handler = type(a_metatable) == 'table' and rawget(a_metatable, '__eq')
  if not handler then
    handler = type(b_metatable) == 'table' and rawget(b_metatable, '__eq')
  end
  if not handler then return false end
  return not not handler(a, b)
end

--- Builds an unpack that reads elements through __index and the count
-- through __len, as Lua 5.3's table.unpack does, from one that reads
-- them raw.
-- @param raw_unpack The interpreter's own unpack.
-- @param len A length function that honours __len.
-- @return An unpack function with table.unpack's signature.
function M.make_unpack(raw_unpack, len)
  return function(list, first, last)
    first = first or 1
    last = last or len(list)
    if raw_getmetatable(list) == nil then
      return raw_unpack(list, first, last)
    end
    local values = {}
    for i = first, last do
      values[i - first + 1] = list[i]
    end
    return raw_unpack(values, 1, last - first + 1)
  end
end

-- tostring's result for a table or userdata with its metatable set
-- aside, so a __tostring cannot answer: 'table: 0x...'.
local function raw_tostring(value, metatable)
  if not (debug_library and debug_library.setmetatable) then
    return type(value)
  end
  debug_library.setmetatable(value, nil)
  local text = tostring(value)
  debug_library.setmetatable(value, metatable)
  return text
end

-- A __tostring that answers as Lua 5.3+ does for a metatable with a
-- string __name and no __tostring: '<name>: <address>'.
local function name_tostring(value)
  local metatable = raw_getmetatable(value)
  local text = raw_tostring(value, metatable)
  local name = type(metatable) == 'table' and rawget(metatable, '__name')
  if type(name) ~= 'string' then
    return text
  end
  return name .. ':' .. (text:match('^[^:]*:(.*)$') or (' ' .. text))
end

--- Gives a metatable the default string form Lua 5.3+ derives from
-- its `__name` field, `'<name>: <address>'`, for a Lua that does not.
-- A metatable that already has a __tostring keeps it.
--
-- Reaching the address needs debug.setmetatable; without the debug
-- library the form is `'<name>: <type>'`.
-- @param metatable The metatable to extend; modified in place.
-- @return metatable.
function M.add_name_tostring(metatable)
  if rawget(metatable, '__tostring') == nil then
    rawset(metatable, '__tostring', name_tostring)
  end
  return metatable
end

local function index_next(list, index)
  index = index + 1
  local value = list[index]
  if value ~= nil then
    return index, value
  end
end

--- Iterates list[1], list[2], ... up to the first nil, reading each
-- through __index, as Lua 5.3+'s ipairs does.
-- @param list The table (or object with __index) to iterate.
-- @return An iterator function, the list, and 0.
function M.ipairs(list)
  return index_next, list, 0
end

--- The subtype of a number, as math.type reports it on Lua 5.3+.
-- Without an integer subtype, every whole finite number counts as an
-- integer, so `1.0` is reported as 'integer'.
-- @param value Any value.
-- @return 'integer', 'float', or nil when value is not a number.
function M.math_type(value)
  if type(value) ~= 'number' then return nil end
  if value % 1 == 0 then return 'integer' end
  return 'float'
end

--- Adds the integer-operator metamethods (`__idiv`, `__band`, `__bor`,
-- `__bxor`, `__shl`, `__shr`, `__bnot`) to a metatable, each applying
-- the operator to its unwrapped operands.
--
-- A Lua before 5.3 has none of these operators and never calls the
-- metamethods, so this version adds nothing.
-- @param metatable The metatable to extend; modified in place.
-- @param unwrap Maps an operand to the value the operator applies to.
--   Not called by this version.
-- @return metatable.
function M.add_integer_operator_metamethods(metatable, unwrap)
  return metatable
end

--- Encodes a number as the 8 bytes of a little-endian IEEE 754
-- double, as `string.pack('<d', value)` does.
--
-- Needs math.frexp, which Lua 5.1 and 5.2 provide; the 5.3+ layer
-- replaces this with string.pack.
-- @param value A number. Every NaN encodes as the same quiet NaN.
-- @return An 8-byte string.
function M.pack_double(value)
  local sign = 0
  if value < 0 or (value == 0 and 1 / value < 0) then
    sign = 1
    value = -value
  end
  local exponent, mantissa
  if value ~= value then
    exponent, mantissa = 2047, 2 ^ 51
  elseif value == math.huge then
    exponent, mantissa = 2047, 0
  elseif value == 0 then
    exponent, mantissa = 0, 0
  else
    local fraction, power = math.frexp(value)
    exponent = power + 1022
    if exponent <= 0 then
      -- Subnormal: value is mantissa * 2^-1074. Scaling in two steps
      -- keeps the intermediate finite.
      exponent, mantissa = 0, value * 2 ^ 1022 * 2 ^ 52
    else
      mantissa = (fraction * 2 - 1) * 2 ^ 52
    end
  end
  local bytes = {}
  for i = 1, 6 do
    local byte = mantissa % 256
    bytes[i] = byte
    mantissa = (mantissa - byte) / 256
  end
  bytes[7] = exponent % 16 * 16 + mantissa
  bytes[8] = sign * 128 + floor(exponent / 16)
  return string.char(bytes[1], bytes[2], bytes[3], bytes[4],
                     bytes[5], bytes[6], bytes[7], bytes[8])
end

return M

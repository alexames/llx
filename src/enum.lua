-- Copyright 2025 Alexander Ames <Alexander.Ames@gmail.com>

local compat = require 'llx.compat'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local enum_metatable = {
  __tointeger = function(self)
    return self.value
  end,

  __tostring = function(self)
    return self.enum.__name .. '.' .. self.name
  end,

  __tostringf = function(self, formatter)
    formatter:insert(tostring(self))
  end,

  __eq = function(a, b)
    return a.enum == b.enum and a.value == b.value
  end,

  __lt = function(a, b)
    return a.value < b.value
  end,

  __le = function(a, b)
    return a.value <= b.value
  end,

  __hash = function(self, result)
    -- Combine the enum's name with the numeric value. Equal enum
    -- values (same enum table, same value) always hash the same;
    -- different enums with the same name can collide, which __eq
    -- resolves correctly by comparing enum table identity.
    local hash = require 'llx.hash'
    result = hash.hash_value(self.enum.__name, result)
    result = hash.hash_value(self.value, result)
    return result
  end,
}

function enum(name)
  local enum_table = {
    __name=assert(
      type(name) == 'string' and name,
      'enums must have a string name')
  }
  return function(t)
    for k, v in compat.pairs(t) do
      local enum_object = setmetatable(
        {enum=enum_table, name=v, value=k}, enum_metatable)
      if enum_table[k] == nil then
        enum_table[k] = enum_object
      end
      if enum_table[v] == nil then
        enum_table[v] = enum_object
      end
    end
    return enum_table
  end
end

-- ---------------------------------------------------------------------------
-- Flag: bitfield enum.
--
-- Members carry power-of-two values. Combinations are produced via
-- |, &, ~, and - (bit-clear). Combined values still know their
-- enum and can be checked with :has().
-- ---------------------------------------------------------------------------

local flag_metatable
local function make_flag(enum_table, value)
  return setmetatable(
    {enum = enum_table, value = value}, flag_metatable)
end

-- The methods every flag value has. The operators `|`, `&` and `~`
-- (Lua 5.3+) and `-` are spelled in terms of them, so code that must
-- run on an earlier Lua calls them by name.
local flag_methods = {
  --- Whether every bit of `other` is set in this flag.
  -- @param this The flag value.
  -- @param other A flag value or an integer bit mask.
  -- @return true when all of other's bits are set.
  has = function(this, other)
    local other_value = type(other) == 'number' and other or other.value
    return compat.band(this.value, other_value) == other_value
  end,

  --- The bits set in either flag; `a | b`.
  -- @param a A flag value.
  -- @param b A flag value of the same enum.
  -- @return A new flag value.
  union = function(a, b)
    return make_flag(a.enum, compat.bor(a.value, b.value))
  end,

  --- The bits set in both flags; `a & b`.
  -- @param a A flag value.
  -- @param b A flag value of the same enum.
  -- @return A new flag value.
  intersection = function(a, b)
    return make_flag(a.enum, compat.band(a.value, b.value))
  end,

  --- The bits set in exactly one of the flags; `a ~ b`.
  -- @param a A flag value.
  -- @param b A flag value of the same enum.
  -- @return A new flag value.
  symmetric_difference = function(a, b)
    return make_flag(a.enum, compat.bxor(a.value, b.value))
  end,

  --- The bits of `a` with those of `b` cleared; `a - b`.
  -- @param a A flag value.
  -- @param b A flag value of the same enum.
  -- @return A new flag value.
  difference = function(a, b)
    return make_flag(a.enum, compat.band(a.value, compat.bnot(b.value)))
  end,
}

flag_metatable = {
  __tointeger = function(self) return self.value end,

  __tostring = function(self)
    if self.value == 0 then
      return self.enum.__name .. '.<none>'
    end
    local parts = {}
    for _, member in ipairs(self.enum._members) do
      if compat.band(self.value, member.value) == member.value
          and member.value ~= 0 then
        parts[#parts + 1] = member.name
      end
    end
    if #parts == 0 then
      -- Has bits we don't recognize as named members.
      return self.enum.__name .. '<' .. tostring(self.value) .. '>'
    end
    return self.enum.__name .. '.' .. table.concat(parts, '|')
  end,

  __tostringf = function(self, formatter)
    formatter:insert(tostring(self))
  end,

  __eq = function(a, b)
    return a.enum == b.enum and a.value == b.value
  end,

  __lt = function(a, b) return a.value < b.value end,
  __le = function(a, b) return a.value <= b.value end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    result = hash.hash_value(self.enum.__name, result)
    result = hash.hash_value(self.value, result)
    return result
  end,

  __bor = function(a, b) return flag_methods.union(a, b) end,
  __band = function(a, b) return flag_methods.intersection(a, b) end,
  __bxor = function(a, b) return flag_methods.symmetric_difference(a, b) end,
  __sub = function(a, b) return flag_methods.difference(a, b) end,

  __index = function(self, k)
    local method = flag_methods[k]
    if method then
      return method
    end
    if k == 'name' then
      -- Build the name lazily from the bit composition so combined
      -- flags get useful names too.
      return tostring(self):match('%.(.*)$') or ''
    end
    return nil
  end,
}

function Flag(name)
  assert(type(name) == 'string', 'Flag enums must have a string name')
  local enum_table = {
    __name = name,
    __is_flag = true,
    _members = {},
  }
  return function(spec)
    -- Collect members first so we can sort by value for stable
    -- __tostring output across runs.
    local members = {}
    for member_name, value in compat.pairs(spec) do
      if type(member_name) ~= 'string' then
        error('Flag members must have string names', 2)
      end
      if type(value) ~= 'number' or compat.math_type(value) ~= 'integer' then
        error(compat.format(
          'Flag member %q must have an integer value', member_name), 2)
      end
      members[#members + 1] = {name = member_name, value = value}
    end
    table.sort(members, function(a, b) return a.value < b.value end)
    for _, m in ipairs(members) do
      local flag_obj = make_flag(enum_table, m.value)
      -- Store the canonical name so tostring on the singleton
      -- doesn't need to compose.
      rawset(flag_obj, '_canonical_name', m.name)
      if enum_table[m.name] then
        error(compat.format(
          'duplicate Flag member name %q', m.name), 2)
      end
      enum_table[m.name] = flag_obj
      enum_table._members[#enum_table._members + 1] =
        {name = m.name, value = m.value}
    end
    return enum_table
  end
end

return _M

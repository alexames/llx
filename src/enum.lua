-- Copyright 2025 Alexander Ames <Alexander.Ames@gmail.com>

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
    for k, v in pairs(t) do
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

flag_metatable = {
  __tointeger = function(self) return self.value end,

  __tostring = function(self)
    if self.value == 0 then
      return self.enum.__name .. '.<none>'
    end
    local parts = {}
    for _, member in ipairs(self.enum._members) do
      if (self.value & member.value) == member.value
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

  __bor = function(a, b)
    return make_flag(a.enum, a.value | b.value)
  end,

  __band = function(a, b)
    return make_flag(a.enum, a.value & b.value)
  end,

  __bxor = function(a, b)
    return make_flag(a.enum, a.value ~ b.value)
  end,

  __sub = function(a, b)
    -- a - b removes the bits of b from a.
    return make_flag(a.enum, a.value & ~b.value)
  end,

  __index = function(self, k)
    if k == 'has' then
      return function(this, other)
        local other_value = type(other) == 'number' and other or other.value
        return (this.value & other_value) == other_value
      end
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
    for member_name, value in pairs(spec) do
      if type(member_name) ~= 'string' then
        error('Flag members must have string names', 2)
      end
      if type(value) ~= 'number' or math.type(value) ~= 'integer' then
        error(string.format(
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
        error(string.format(
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

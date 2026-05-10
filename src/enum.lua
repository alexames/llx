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

return _M

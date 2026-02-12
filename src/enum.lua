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
}

function enum(name)
  local enum_table = {
    __name=assert(type(name) == 'string' and name, 'enums must have a string name')
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


local class_module  = require 'llx.class'
local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local hash = require 'llx.hash'

local _ENV, _M = environment.create_module_environment()

local class  = class_module.class

Tuple = class 'Tuple' {
  __init = function(self, t)
    local values = {}
    rawset(self, '__values', values)
    for i=1, #t do
      values[i] = t[i]
    end
  end,

  unpack = function(self)
    return table.unpack(self)
  end,

  __index = function(self, key)
    return Tuple.__defaultindex(self, key) or self.__values[key]
  end,

  __len = function(self, key)
    return #self.__values
  end,

  __eq = function(self, other)
    if #self ~= #other then
      return false
    end
    for i=1, #self do
      if self[i] ~= other[i] then
        return false
      end
    end
    return true
  end,

  __lt = function(self, other)
    local len = math.min(#self, #other)
    for i = 1, len do
      if self[i] < other[i] then return true end
      if other[i] < self[i] then return false end
    end
    return #self < #other
  end,

  __le = function(self, other)
    local len = math.min(#self, #other)
    for i = 1, len do
      if self[i] < other[i] then return true end
      if other[i] < self[i] then return false end
    end
    return #self <= #other
  end,

  __hash = function(self, result)
    for i=1, #self do
      result = hash.hash_value(i, result)
      result = hash.hash_value(self[i], result)
    end
    return result
  end,

  __newindex = function(self, k, v)
    error(exceptions.NotImplementedError())
  end,

  __tostring = function(self)
    return 'Tuple{' .. table.concat(self, ',') .. '}'
  end,
}

return _M

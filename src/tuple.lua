
local class  = require 'llx/src/class' . class
local environment = require 'llx/src/environment'
local exceptions = require 'llx/src/exceptions'
local hash = require 'llx/src/hash'

local _ENV, _M = environment.create_module_environment()

Tuple = class 'Tuple' {
  __init = function(self, t)
    local values = {}
    rawset(self, '__values', values)
    for i=1, #t do
      values[i] = t[i]
    end
  end,

  __index = function(self, key)
    return self.__values[key]
  end,

  __len = function(self, key)
    return #self.__values
  end,

  -- todo: make self first
  __hash = function(result, self)
    for i=1, #self do
      result = hash.hash_value(result, i)
      result = hash.hash_value(result, self[i])
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

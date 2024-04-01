
local class  = require 'llx/src/class' . class
local environment = require 'llx/src/environment'
local exceptions = require 'llx/src/exceptions'

local _ENV, _M = environment.create_environment()

Tuple = class 'Tuple' {
  __init = function(self, t)
    local values = {}
    for i, v in iparis(t) do
      values[i] = v
    end
    self.__index = function(self, key)
      return rawget(values, key)
    end
  end,

  __hash = function()
  end,

  __newindex = function(self, k, v)
    error(exceptions.NotImplementedError())
  end
}

return _M

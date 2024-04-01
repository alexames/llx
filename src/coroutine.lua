-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class  = require 'llx/src/class' . class
local Decorator = require 'llx/src/decorator' . Decorator
local environment = require 'llx/src/environment'

local _ENV, _M = environment.create_module_environment()

--- Wrap the member function using `coroutine.wrap`.
WrapDecorator = class 'WrapDecorator' : extends(Decorator) {
  decorate = function(self, class_table, name, value)
    local function wrapped_function(...)
      local args = {...}
      return coroutine.wrap(function() value(table.unpack(args)) end)
    end
    return class_table, name, wrapped_function
  end,
}

wrap = WrapDecorator()

return _M

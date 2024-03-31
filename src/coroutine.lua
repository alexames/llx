-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class  = require 'llx/src/class' . class
local Decorator = require 'llx/src/decorator' . Decorator
local scoped_env = require 'llx/src/scoped_environment'

local co_wrap = coroutine.wrap
local unpack = table.unpack
local _ENV <close> = scoped_env.create_environment()

--- Wrap the member function using `coroutine.wrap`.
WrapDecorator = class 'WrapDecorator' : extends(Decorator) {
  decorate = function(self, class_table, name, value)
    local function wrapped_function(...)
      local args = {...}
      return co_wrap(function() value(unpack(args)) end)
    end
    return class_table, name, wrapped_function
  end,
}

wrap = WrapDecorator()

return _ENV

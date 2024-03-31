-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class  = require 'llx/src/class' . class
local Decorator = require 'llx/src/decorator' . Decorator

--- Treat a getter/setter pair on a table as a field.
local CoroutineDecorator = class 'CoroutineDecorator' : extends(Decorator) {
  decorate = function(self, class_table, name, value)
    local function wrapped_function(...)
      local args = {...}
      return coroutine.wrap(function() value(table.unpack(args)) end)
    end
    return class_table, name, wrapped_function
  end,
}

return {
  wrap=CoroutineDecorator(),
}

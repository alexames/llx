-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

--- A base class for class method decorators.
--
-- When defining a decorator, you must supply a decorate member function, which
-- takes the target class, name of the function, and the value to assign to it.
-- You can use this to re-direct where the function is stored, the key in the
-- table in which it is stored, or the value that gets stored there.
--
-- The Decorator class overrides the or operator ('|') so that it can be used
-- like so:
--
--     Fibonacci = class 'Fibonacci' {
--       ['fib' | Cache()] = function(self, i)
--         if i <= 1 then
--           return i
--         else
--           return self:fib(i-1) + self:fib(i-2)
--         end
--       end,
--     }
--
-- Decorators can also be chained, so you can apply more than by simply using
-- the or operator again for each decorator. Classes have special handling for
-- decorators, and will apply them in the order they appear

local class  = require 'llx/src/class' . class
local environment = require 'llx/src/environment'

local _ENV, _M = environment.create_module_environment()

Decorator = class 'Decorator' {
  __bor = function(lhs, self)
    if type(lhs) == 'table' and lhs.__isdecorator then
      table.insert(lhs.decorator_table, self)
      return lhs
    else
      return {__isdecorator=true, name=lhs, decorator_table={self}}
    end
  end,

  decorate = function(self, class, name, value)
    return class, name, value
  end
}

return _M

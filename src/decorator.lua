-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

--- A base class for class method decorators.
--
-- When defining a decorator, you must supply a decorate member function, which
-- takes the target class, name of the function, and the value to assign to it.
-- You can use this to re-direct where the function is stored, the key in the
-- table in which it is stored, or the value that gets stored there.
--
-- A decorated class field is keyed by `decorated(name, ...)`:
--
--     Fibonacci = class 'Fibonacci' {
--       [decorated('fib', cache)] = function(self, i)
--         if i <= 1 then
--           return i
--         else
--           return self:fib(i-1) + self:fib(i-2)
--         end
--       end,
--     }
--
-- More than one decorator can be given, `decorated('f', a, b)`; the class
-- applies them in the order they are listed.

local class  = require 'llx.class' . class
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

Decorator = class 'Decorator' {

  decorate = function(self, class, name, value)
    return class, name, value
  end
}

--- Builds the key of a decorated class field.
-- @param name The field name the decorated value is stored under.
-- @param ... The decorators, applied in the order given.
-- @return A decorated key for a class definition table: a table with
--   `__isdecorator = true`, the `name`, and the decorators in
--   `decorator_table`.
function decorated(name, ...)
  return {__isdecorator=true, name=name, decorator_table={...}}
end

return _M

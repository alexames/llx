require 'ext'

local class = require 'lx/class'
local type_check_decorator = require 'types/type_check_decorator'

local method = class 'method' {
  __init = function(self, function_args)
    local underlying_function = function_args[1]
    for _, decorator in ipairs(function_args.decorators or {}) do
      underlying_function = decorator(underlying_function)
    end
    self.underlying_function = type_check_decorator(underlying_function, function_args.types)
  end;

  __call = function(self, ...)
    return self.underlying_function(...)
  end;
}

return method

-- TODO:
-- Move join to common utility file
-- Fix error message to be more like built in error message:
--   `bad argument #2 to 'format' (string expected, got nil)`
-- Make it work better with built in types, so you can specify strings with just
--   `string` or `number` instead of having to use type.String, etc
--   this could be done by adding functions directly to the tables for each type
--   or by having a table that uses those types as a key, or something else?
-- Improve lists so they are intrinsically typed
-- Add a dict type checker
-- Add a tuple type checker, both intrinsically typed and not
-- refactor error message to just return a string, and allow them to compose better
-- Add examples of other things that can be checked for, like even numbers
-- better handling of metatable/userdata types
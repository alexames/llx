require 'llx/src/class'
local type_check_decorator = require 'llx/src/type_check_decorator'

method = class 'method' {
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
-- Improve lists so they are intrinsically typed
-- Add a dict type checker
-- Add a tuple type checker, both intrinsically typed and not
-- refactor error message to just return a string, and allow them to compose better
-- Add examples of other things that can be checked for, like even numbers
-- better handling of metatable/userdata types
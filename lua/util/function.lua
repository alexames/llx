local from = require 'util/import'
require 'ext/string'

local class = from 'util/class' : import 'class'
local type_check_decorator = from 'types/type_check_decorator'
                           : import 'type_check_decorator'

local Function = class 'Function' {
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

local function test()
  local Any, List, Number, Optional, String, Union = types.Any, types.List, types.Number, types.Optional, types.String, types.Union

  local f = Function{
    decorators={cache.lru(10)};
    types={
      args={Number, List{Union{String, Number}}, Optional{Any}},
      returns={Number}};
    function(i)
      print('hello')
      return 10
    end
  }

  print(f(10, {'false'}))
  print(f(10, {'safdsdf', 'sfsf', 10, 'false'}, 3))
end


return {
  Function=Function,
  test=test,
}

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
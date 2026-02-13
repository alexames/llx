-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

--- Core utility functions for the llx library.
-- Provides fundamental utilities for metatable manipulation, introspection,
-- iteration, comparison, and common predicates.
-- @module llx.core

local environment = require 'llx.environment'
local isinstance = require 'llx.isinstance' . isinstance

local _ENV, _M = environment.create_module_environment()

--- Gets a metafield from an object's metatable.
-- Safely retrieves a field from the metatable of an object without triggering
-- any metamethods.
-- @param t The object to inspect
-- @param k The metafield key to retrieve
-- @return The value of the metafield, or nil if not found
-- @usage
-- local mt = getmetafield(obj, '__tostring')
-- if mt then print('Object has custom tostring') end
function getmetafield(t, k)
  local metatable = debug.getmetatable(t)
  return metatable and rawget(metatable, k)
end

--- Checks if a value is callable.
-- Returns true if the value is a function or has a __call metamethod.
-- @param v The value to check
-- @return true if callable, false otherwise
-- @usage
-- if is_callable(obj) then obj() end
function is_callable(v)
  if type(v) == 'function' then return true end
  if type(v) ~= 'table' and type(v) ~= 'userdata' then return false end
  local metafield = getmetafield(v, '__call')
  return metafield and type(metafield) == 'function'
end

--- Prints a formatted string.
-- Wrapper around print(string.format(...)).
-- @param fmt Format string
-- @param ... Format arguments
-- @usage printf("Hello %s, you have %d messages", name, count)
function printf(fmt, ...)
  print(string.format(fmt, ...))
end

--- Gets the file path of the script at a given call stack level.
-- @param level Stack level (default: 1, meaning the caller)
-- @return The file path of the script
-- @usage local path = script_path()
function script_path(level)
   return debug.getinfo((level or 1) + 1, "S").source:sub(2)
end

--- Checks if the current script is the main entry point.
-- Returns true if the script was run directly (not required as a module).
-- @param level Stack level adjustment (default: 1)
-- @return true if this is the main file, false otherwise
-- @usage
-- if main_file() then
--   run_tests()
-- end
function main_file(level)
  return script_path((level or 1) + 1) == arg[0]
end

--- Normalizes metamethod arguments for commutative operations.
-- When implementing metamethods like __add, Lua may pass the operands
-- in either order. This function ensures the class instance is first.
-- @param class The class to check against
-- @param self First operand
-- @param other Second operand
-- @return self, other (reordered so self is an instance of class)
-- @usage
-- __add = function(self, other)
--   self, other = metamethod_args(MyClass, self, other)
--   -- Now self is guaranteed to be MyClass instance
-- end
function metamethod_args(class, self, other)
  if isinstance(self, class) then
    return self, other
  else
    return other, self
  end
end

--- Iterator over table values.
-- Returns an iterator that yields values from a table.
-- @param t The table to iterate over
-- @return Iterator function
-- @usage for v in values(t) do print(v) end
function values(t)
  local k = nil
  return function()
    local v
    k, v = next(t, k)
    return v
  end
end

--- Iterator over array values.
-- Returns an iterator that yields values from an array-like table.
-- @param t The table to iterate over
-- @return Iterator function
-- @usage for value in ivalues(t) do print(value) end
function ivalues(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

--- Three-way comparison function.
-- Returns -1, 0, or 1 based on comparison of two values.
-- @param a First value
-- @param b Second value
-- @return -1 if a < b, 0 if a == b, 1 if a > b
-- @usage
-- result = cmp(5, 10)  -- returns -1
-- result = cmp(10, 10) -- returns 0
-- result = cmp(15, 10) -- returns 1
function cmp(a, b)
  if a == b then return 0
  elseif a < b then return -1
  else return 1
  end
end

--- Returns the lesser of two values.
-- Stable: when equal, returns the first argument (a).
-- @param a First value (must support < comparison)
-- @param b Second value (must support < comparison)
-- @return The lesser of a and b
-- @usage min_val = lesser(5, 10)  -- returns 5
function lesser(a, b)
  if b < a then return b else return a end
end

--- Returns the greater of two values.
-- Stable: when equal, returns the second argument (b).
-- @param a First value (must support < comparison)
-- @param b Second value (must support < comparison)
-- @return The greater of a and b
-- @usage max_val = greater(5, 10)  -- returns 10
function greater(a, b)
  if b < a then return a else return b end
end

--- Checks if a number is even.
-- @param v The number to check
-- @return true if even, false if odd
-- @usage if even(4) then print("even") end
function even(v) return v % 2 == 0 end

--- Checks if a number is odd.
-- @param v The number to check (must be an integer)
-- @return true if odd, false if even
-- @usage if odd(3) then print("odd") end
function odd(v) return v % 2 ~= 0 end

--- Checks if a value is not nil.
-- Useful as a predicate function for filter operations.
-- @param v The value to check
-- @return true if v is not nil, false otherwise
-- @usage List{1, nil, 3}:filter(nonnil)  -- returns {1, 3}
function nonnil(v)
  return v ~= nil
end

--- Identity/no-operation function.
-- Returns all arguments unchanged. Useful as a default transformation.
-- @param ... Any arguments
-- @return All arguments unchanged
-- @usage local x, y = noop(1, 2)  -- x=1, y=2
function noop(...) return ... end

--- Evaluates a Lua expression string.
-- Parses and executes a string as a Lua expression, returning the result.
-- @param s The expression string to evaluate (must be a valid Lua expression)
-- @return The result of evaluating the expression
-- @usage local x = tovalue("1 + 2")  -- returns 3
function tovalue(s)
  assert(type(s) == 'string', 'tovalue: expected string, got ' .. type(s))
  local chunk, err = load('return ' .. s)
  if not chunk then
    error('tovalue: invalid expression: ' .. err, 2)
  end
  return chunk()
end

--- Returns true if v is a table.
-- @param v The value to check
-- @return boolean
function is_table(v) return type(v) == 'table' end

--- Returns true if v is a string.
-- @param v The value to check
-- @return boolean
function is_string(v) return type(v) == 'string' end

--- Returns true if v is a number.
-- @param v The value to check
-- @return boolean
function is_number(v) return type(v) == 'number' end

--- Returns true if v is a function.
-- @param v The value to check
-- @return boolean
function is_function(v) return type(v) == 'function' end

--- Returns true if v is a boolean.
-- @param v The value to check
-- @return boolean
function is_boolean(v) return type(v) == 'boolean' end

--- Returns true if v is nil.
-- @param v The value to check
-- @return boolean
function is_nil(v) return v == nil end

--- Shallow-clones a value.
-- Tables are shallow-copied; non-table values are returned unchanged.
-- @param v The value to clone
-- @return A shallow copy of v
function clone(v)
  if type(v) ~= 'table' then return v end
  local copy = {}
  for k, val in pairs(v) do
    copy[k] = val
  end
  return setmetatable(copy, getmetatable(v))
end

--- Calls a function n times, collecting results into a List.
-- @param n Number of times to call
-- @param f Function to call; receives the 1-based index as argument
-- @return A List of results
function times(n, f)
  local List = require('llx.types.list').List
  local result = List{}
  for i = 1, n do
    result:insert(f(i))
  end
  return result
end

--- Creates a function from predicate/transformer pairs.
-- The first pair whose predicate returns true determines the result.
-- @param pairs A table of {predicate, transformer} pairs
-- @return A function that applies the first matching transformer
function cond(pairs)
  return function(...)
    for i = 1, #pairs do
      local predicate = pairs[i][1]
      local transformer = pairs[i][2]
      if predicate(...) then
        return transformer(...)
      end
    end
    return nil
  end
end

--- Materializes any iterator into a List.
-- @param iterator An iterator function
-- @return A List of all yielded values
function collect(iterator)
  local List = require('llx.types.list').List
  local result = List{}
  for _, v in iterator do
    result:insert(v)
  end
  return result
end

return _M

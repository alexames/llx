-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class_module = require 'llx.class'
local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local getclass_module = require 'llx.getclass'
local isinstance_module = require 'llx.isinstance'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class
local getclass = getclass_module.getclass
local isinstance = isinstance_module.isinstance
local InvalidArgumentException = exceptions.InvalidArgumentException

local function check_types(location, expected_types, argument_list)
  for index, expected_type in ipairs(expected_types or {}) do
    local value = argument_list[index]
    local correct = isinstance(value, expected_type)
    if not correct then
      error(InvalidArgumentException(index, expected_type, getclass(value)))
    end
  end
end

-- Cached upvalue for the deferred require of llx.types.matchers
-- (deferred to avoid a load-time cycle: this module's dependencies
-- pull in llx.types, and therefore llx.types.matchers, through
-- llx.getclass).
local matchers_module = nil

-- Runs check_types inside a TypeVar binding scope (llx.types.matchers)
-- and returns the scope, re-raising any check failure only after the
-- scope has been exited. `scope` re-enters an existing scope (nil
-- opens a fresh one), which is how the argument and return checks of
-- one call share their bindings -- the same threading llx.signature
-- applies around Signature-wrapped calls.
local function check_types_in_scope(location, expected_types,
                                    argument_list, scope)
  matchers_module = matchers_module or require 'llx.types.matchers'
  scope = matchers_module.enter_type_var_scope(scope)
  local ok, err = pcall(check_types, location, expected_types,
                        argument_list)
  matchers_module.exit_type_var_scope()
  if not ok then
    error(err, 0)
  end
  return scope
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function type_check_decorator(underlying_function, expected_types)
  if not expected_types then
    return underlying_function
  end
  local argument_types = expected_types.args
  local return_types = expected_types.returns
  local function type_checker(underlying_function)
    return function(...)
      -- Arguments and returns share one TypeVar binding scope, so a
      -- variable bound from a parameter constrains the return values
      -- of the same call. The scope is only entered for the duration
      -- of each synchronous check, never across the wrapped
      -- function's body (keeping recursion and coroutines safe).
      local scope = check_types_in_scope(
          'argument', argument_types, {...})
      local result = {underlying_function(...)}
      check_types_in_scope('return', return_types, result, scope)
      return table.unpack(result)
    end
  end
  return type_checker(underlying_function)
end

return _M

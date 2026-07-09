-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Checked casts: the runtime analog of static cast/TypeGuard
-- narrowing.
--
-- cast(value, T) returns value unchanged when it satisfies T and
-- raises TypeError otherwise, so inline assertions read as
-- expressions:
--   local n = cast(config.count, Integer)
-- try_cast(value, T) is the non-raising variant: it returns
-- Ok(value) on success or Err(TypeError) on mismatch, for callers
-- that want to branch without pcall.
--
-- Both delegate to isinstance, so they work with every class and
-- matcher (Union, Optional, ...) that implements __isinstance.
-- @module llx.cast

local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local getclass_module = require 'llx.getclass'
local isinstance_module = require 'llx.isinstance'
local result_module = require 'llx.result'

local _ENV, _M = environment.create_module_environment()

local TypeError = exceptions.TypeError
local getclass = getclass_module.getclass
local isinstance = isinstance_module.isinstance
local Ok = result_module.Ok
local Err = result_module.Err

local function type_name(type)
  return type.__name or tostring(type)
end

-- A nil expected type is a bug at the call site, not a failed
-- cast, so both entry points raise rather than returning Err.
local function check_type_argument(expected_type)
  if expected_type == nil then
    error(TypeError('expected a type, got nil', 3))
  end
end

-- Builds the TypeError describing a failed cast.
local function cast_error(value, expected_type)
  local what = string.format(
      '%s expected, got %s',
      type_name(expected_type), type_name(getclass(value)))
  return TypeError(what, 3)
end

--- Returns value if it satisfies expected_type, raising otherwise.
-- Delegates the check to isinstance, so any type with an
-- __isinstance metamethod (classes, built-in type tables, and
-- matchers such as Union or Optional) is accepted.
-- @param value The value to check
-- @param expected_type The type or matcher value must satisfy
-- @return value, unchanged, when the check passes
-- @raise TypeError when the check fails
function cast(value, expected_type)
  check_type_argument(expected_type)
  if isinstance(value, expected_type) then
    return value
  end
  error(cast_error(value, expected_type))
end

--- Non-raising variant of cast returning a Result.
-- @param value The value to check
-- @param expected_type The type or matcher value must satisfy
-- @return Ok(value) when the check passes, Err(TypeError) when it
-- fails
function try_cast(value, expected_type)
  check_type_argument(expected_type)
  if isinstance(value, expected_type) then
    return Ok(value)
  end
  return Err(cast_error(value, expected_type))
end

return _M

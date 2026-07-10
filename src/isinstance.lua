-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

-- Cached upvalues for deferred requires. Both modules are pulled in
-- lazily, on the error path only: llx.getclass requires llx.types and
-- therefore llx.types.matchers, which requires this module back, so a
-- load-time require would cycle; llx.exceptions is deferred for the
-- same reason (via llx.hash) and to keep the happy path free of any
-- load cost.
local exceptions_module = nil
local getclass_module = nil

-- Raises the "bad matcher" error for a non-matcher second argument.
-- Named per llx convention (argument #2 of isinstance) so the message
-- points at the actual mistake instead of an internal index error.
-- Level 4 anchors the traceback at isinstance's caller: level 2 is
-- this helper and level 3 the isinstance frame, both machinery.
local function raise_bad_type_argument(expected_type)
  exceptions_module = exceptions_module or require 'llx.exceptions'
  getclass_module = getclass_module or require 'llx.getclass'
  error(exceptions_module.InvalidArgumentException(
      2,
      'expected a type matcher or class with __isinstance, got '
      .. getclass_module.describe_value(expected_type), 4))
end

--- Checks whether a value is an instance of a type.
-- Dispatches to the type's __isinstance metafield, so every llx class
-- and matcher (Union, Optional, ListOf, ...) is supported. The type
-- argument must actually be such a matcher or class: a plain string,
-- number, or table without __isinstance raises
-- InvalidArgumentException naming argument #2 rather than failing
-- with an obscure index error (or silently returning false).
-- @param value The value to check
-- @param expected_type A type matcher or class with __isinstance
-- @return Whatever the type's __isinstance returns (a boolean, plus
-- an optional second value some matchers use to explain failures)
function isinstance(value, expected_type)
  if type(expected_type) ~= 'table' then
    raise_bad_type_argument(expected_type)
  end
  local __isinstance = expected_type.__isinstance
  if not __isinstance then
    raise_bad_type_argument(expected_type)
  end
  return __isinstance(expected_type, value)
end

return _M

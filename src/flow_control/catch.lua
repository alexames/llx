-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx.core'
local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local getclass_module = require 'llx.getclass'

local _ENV, _M = environment.create_module_environment()

local InvalidArgumentException = exceptions.InvalidArgumentException
local describe_value = getclass_module.describe_value
local is_callable = core.is_callable

--- Builds a catch clause for the try/catch DSL.
-- The exception argument selects which thrown values the clause
-- handles: a class or type matcher (anything isinstance accepts) is
-- dispatched through its callable __isinstance, and a string matches
-- any thrown value whose class -- or any superclass, unlike the
-- exact-name string matching of Signature params -- is named by it.
-- Anything else is rejected here, at construction time: a bad catch
-- type used to sit silently unmatched (or, after the isinstance
-- guard of #67, raise from inside the unwind path and mask the
-- exception being handled), so it now fails at the catch() call site
-- with a clear message instead (#92).
-- @param exception A class, type matcher, or class-name string
-- @param handler Function invoked with the caught exception
-- @return A catch clause table for use inside try { ... }
function catch(exception, handler)
  local is_matcher = type(exception) == 'table'
      and is_callable(exception.__isinstance)
  if type(exception) ~= 'string' and not is_matcher then
    error(InvalidArgumentException(
        1,
        'expected an exception class, type matcher, or class-name '
        .. 'string, got ' .. describe_value(exception), 2))
  end
  return {exception=exception, handler=handler}
end

return _M

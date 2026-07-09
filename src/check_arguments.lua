-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local getclass_module = require 'llx.getclass'
local isinstance_module = require 'llx.isinstance'
local table_module = require 'llx.types.table'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class
local Decorator = decorator.Decorator
local getclass = getclass_module.getclass
local InvalidArgumentException = exceptions.InvalidArgumentException
local InvalidArgumentTypeException = exceptions.InvalidArgumentTypeException
local ValueException = exceptions.ValueException
local isinstance = isinstance_module.isinstance
local Table = table_module.Table

local function check_argument(index, value, expected_type)
  if expected_type == nil then
    error(InvalidArgumentException(1, Table, getclass(value), 2))
  end
  local is_correct_type, exception
  if type(expected_type) == 'string' then
    is_correct_type = getclass(value).__name == expected_type
  else
    is_correct_type, exception = isinstance(value, expected_type)
  end
  if not is_correct_type then
    if exception then
      error(InvalidArgumentException(index, exception.what, 4))
    else
      error(InvalidArgumentTypeException(
          index, expected_type, getclass(value), 4))
    end
  end
end

-- Marker for variadic expected-type lists: when it appears as the
-- last entry, any number of additional (unchecked) values is allowed
-- beyond the fixed prefix. It cannot collide with the string form of
-- an expected type, since class names are identifiers.
VARARG = '...'

function check_returns(expected_types, return_values)
  for i=1, #expected_types do
    check_argument(i, return_values[i], expected_types[i])
  end
end

-- Like check_returns, but also rejects values beyond the expected
-- list. `count` must be the exact number of values, as captured by
-- select('#', ...) or table.pack -- the # of the values table is
-- unreliable when embedded nils are present. A trailing VARARG entry
-- in expected_types suppresses the count check: the fixed prefix is
-- still type-checked and any number of extra values is allowed.
function check_returns_exact(expected_types, return_values, count)
  local expected_count = #expected_types
  local variadic = expected_types[expected_count] == VARARG
  local fixed_count = variadic and expected_count - 1 or expected_count
  for i=1, fixed_count do
    if expected_types[i] == VARARG then
      error(ValueException(
          "VARARG ('...') must be the last entry in the expected "
          .. 'types list', 2))
    end
    check_argument(i, return_values[i], expected_types[i])
  end
  if not variadic and count > expected_count then
    error(InvalidArgumentException(
        expected_count + 1,
        string.format(
            'expected at most %d value(s), got %d',
            expected_count, count),
        3))
  end
end

function check_arguments(expected_types)
  local index = 0
  repeat
    index = index + 1
    local name, value = debug.getlocal(2, index)
    local expected_type = expected_types[name]
    if name then
      check_argument(index, value, expected_type)
    end
  until name == nil
end

return _M

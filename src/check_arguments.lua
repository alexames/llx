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

-- Describes the offending value for a mismatch message. Primitives
-- and plain tables report their class per llx.getclass ('Number',
-- 'Table', ...), while class objects and class instances are called
-- out explicitly ('the class Animal', 'an instance of Animal'): a
-- bare class name would be ambiguous between the class itself and an
-- instance of it. The class-object check must come first --
-- getclass(class_object) is the class object itself, so the instance
-- branch would otherwise claim it.
local function describe_actual(value)
  if getclass_module.is_class_object(value) then
    return getclass_module.describe_value(value)
  end
  local value_class = getclass(value)
  if getclass_module.is_class_object(value_class) then
    return 'an instance of '
        .. (value_class.__name or tostring(value_class))
  end
  return value_class
end

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
          index, expected_type, describe_actual(value), 4))
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

-- Cached upvalue for the deferred require of llx.types.matchers
-- (deferred to avoid a load-time cycle: this module's dependencies
-- pull in llx.types, and therefore llx.types.matchers, through
-- llx.getclass).
local matchers_module = nil

-- Like check_returns, but also rejects values beyond the expected
-- list. `count` must be the exact number of values, as captured by
-- select('#', ...) or table.pack -- the # of the values table is
-- unreliable when embedded nils are present. A trailing VARARG entry
-- in expected_types suppresses the count check: the fixed prefix is
-- still type-checked and any number of extra values is allowed.
-- A Rest(T) marker (llx.types.matchers) is rejected anywhere in the
-- list: Rest is only meaningful inside a Tuple element type list,
-- and a signature position holding one could never match any value.
function check_returns_exact(expected_types, return_values, count)
  local expected_count = #expected_types
  local variadic = expected_types[expected_count] == VARARG
  local fixed_count = variadic and expected_count - 1 or expected_count
  if fixed_count > 0 then
    matchers_module = matchers_module or require 'llx.types.matchers'
  end
  for i=1, fixed_count do
    local expected_type = expected_types[i]
    if expected_type == VARARG then
      error(ValueException(
          "VARARG ('...') must be the last entry in the expected "
          .. 'types list', 2))
    end
    if matchers_module.is_rest(expected_type) then
      error(ValueException(
          'Rest(T) is only valid inside Tuple; use a trailing '
          .. "VARARG ('...') for variadic signatures", 2))
    end
    check_argument(i, return_values[i], expected_type)
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

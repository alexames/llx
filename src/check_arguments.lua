-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local getclass_module = require 'llx.getclass'
local isinstance_module = require 'llx.isinstance'

local _ENV, _M = environment.create_module_environment()

local getclass = getclass_module.getclass
local InvalidArgumentException = exceptions.InvalidArgumentException
local InvalidArgumentTypeException = exceptions.InvalidArgumentTypeException
local ValueException = exceptions.ValueException
local isinstance = isinstance_module.isinstance

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

-- `name` is the parameter name when known (the check_arguments
-- path); the check_returns paths have positions, not names, and
-- leave it nil. A nil expected_type means the caller's declaration
-- table has no entry for this value -- a mistake in the checking
-- code itself, so the diagnostic points at the declaration rather
-- than reporting a type mismatch.
local function check_argument(index, value, expected_type, name)
  if expected_type == nil then
    local subject = name
        and string.format("parameter '%s'", name)
        or 'value'
    error(InvalidArgumentException(
        index,
        string.format(
            '%s has no declared type (got %s)',
            subject, describe_actual(value)),
        4))
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
-- An Unpack(Ts) entry splices a TypeVarTuple into the list: the spanned
-- region is a free sequence (no length constraint), and Ts is bound to
-- the types of values in that region for consistency checking on a
-- second occurrence. A Rest(T) marker (llx.types.matchers) is rejected
-- anywhere in the list: Rest is only meaningful inside a Tuple element
-- type list, and a signature position holding one could never match.
function check_returns_exact(expected_types, return_values, count)
  local expected_count = #expected_types
  matchers_module = matchers_module or require 'llx.types.matchers'

  -- Detect Unpack(Ts) placement and validate constraints: at most one,
  -- not combined with trailing VARARG/Rest.
  local unpack_index = nil
  local unpack_var = nil
  for i = 1, expected_count do
    if matchers_module.is_unpack(expected_types[i]) then
      if unpack_index ~= nil then
        error(ValueException(
            'at most one Unpack(Ts) is allowed in the type list', 2))
      end
      unpack_index = i
      unpack_var = expected_types[i].type_var_tuple
    end
  end

  local variadic = expected_count > 0
      and expected_types[expected_count] == VARARG
  if unpack_index ~= nil and variadic then
    error(ValueException(
        'Unpack(Ts) cannot be combined with a trailing VARARG', 2))
  end

  local prefix_count = unpack_index and unpack_index - 1 or 0
  local suffix_count = unpack_index
      and expected_count - unpack_index
      or 0

  if unpack_index ~= nil then
    -- TypeVarTuple splice: check minimum arity and bind the sequence.
    local min_required = prefix_count + suffix_count
    if count < min_required then
      error(InvalidArgumentException(
          min_required + 1,
          string.format(
              'expected at least %d value(s), got %d',
              min_required, count),
          3))
    end
    -- Check fixed prefix.
    for i = 1, prefix_count do
      local expected_type = expected_types[i]
      if matchers_module.is_rest(expected_type) then
        error(ValueException(
            'Rest(T) is only valid inside Tuple', 2))
      end
      if matchers_module.is_type_var_tuple(expected_type) then
        error(ValueException(
            'TypeVarTuple must be wrapped in Unpack(Ts)', 2))
      end
      check_argument(i, return_values[i], expected_type)
    end
    -- Extract and bind the spanned sequence.
    local span_count = count - prefix_count - suffix_count
    local type_sequence = {}
    for i = 1, span_count do
      local value = return_values[prefix_count + i]
      type_sequence[i] = getclass(value).__name
    end
    if not matchers_module.bind_type_var_tuple(unpack_var,
                                              type_sequence) then
      error(InvalidArgumentException(
          prefix_count + 1,
          'TypeVarTuple sequence does not match previously bound '
          .. 'sequence', 3))
    end
    -- Check fixed suffix.
    for j = 1, suffix_count do
      local value_index = count - suffix_count + j
      local expected_type = expected_types[unpack_index + j]
      if matchers_module.is_rest(expected_type) then
        error(ValueException(
            'Rest(T) is only valid inside Tuple', 2))
      end
      if matchers_module.is_type_var_tuple(expected_type) then
        error(ValueException(
            'TypeVarTuple must be wrapped in Unpack(Ts)', 2))
      end
      check_argument(value_index, return_values[value_index],
                     expected_type)
    end
  else
    -- No Unpack: check prefix (up to trailing VARARG) and enforce arity.
    local fixed_count = variadic and expected_count - 1 or expected_count
    for i = 1, fixed_count do
      local expected_type = expected_types[i]
      if expected_type == VARARG then
        error(ValueException(
            "VARARG ('...') must be the last entry in the expected "
            .. 'types list', 2))
      end
      if matchers_module.is_rest(expected_type) then
        error(ValueException(
            'Rest(T) is only valid inside Tuple', 2))
      end
      if matchers_module.is_type_var_tuple(expected_type) then
        error(ValueException(
            'TypeVarTuple must be wrapped in Unpack(Ts)', 2))
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
end

-- Checks the calling function's named parameters (via debug.getlocal)
-- against the {name = type} table. The checks run inside a TypeVar
-- binding scope (llx.types.matchers), the same hooks llx.signature
-- threads through Signature-wrapped calls: a TypeVar named by several
-- parameters binds to the first value checked against it (in
-- parameter order) and every later occurrence must be consistent, so
-- generic correlation works on this path too. The scope covers one
-- check_arguments call and is always exited, even when a check
-- raises; check_arguments has no return-value path, so parameter and
-- return types cannot be correlated here -- use llx.signature for
-- that.
function check_arguments(expected_types)
  -- Walk the caller's frame first: debug.getlocal is level-relative,
  -- so the walk must happen before any wrapping the protected checks
  -- below would introduce.
  local names, values = {}, {}
  local count = 0
  while true do
    local name, value = debug.getlocal(2, count + 1)
    if name == nil then
      break
    end
    count = count + 1
    names[count] = name
    values[count] = value
  end
  matchers_module = matchers_module or require 'llx.types.matchers'
  matchers_module.enter_type_var_scope()
  local ok, err = true, nil
  for index = 1, count do
    ok, err = pcall(check_argument, index, values[index],
                    expected_types[names[index]], names[index])
    if not ok then
      break
    end
  end
  matchers_module.exit_type_var_scope()
  if not ok then
    -- Re-raised unchanged: llx exceptions capture their location at
    -- construction, so the reported position survives; only the raw
    -- traceback gains the pcall frame (the same trade llx.signature
    -- makes).
    error(err, 0)
  end
end

return _M

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

Number = {}

Number.__name = 'Number'

function Number:__isinstance(value)
  return type(value) == 'number'
end

function Number:__validate(schema, path, level, check_field)
  if schema.multiple_of then
    if self % schema.multiple_of ~= 0 then
      local failure_reason = string.format(
          'expected multiple of %s, got %s', schema.multiple_of, self)
      return false, SchemaConstraintFailureException(
          path, failure_reason, level + 1)
    end
  end
  if schema.minimum then
    if self <= schema.minimum then
      local failure_reason = string.format(
          'expected minimum value (inclusive) of %s, got %s', schema.minimum,
          self)
      return false, SchemaConstraintFailureException(
          path, failure_reason, level + 1)
    end
  end
  if schema.exclusive_minimum then
    if self < schema.exclusive_minimum then
      local failure_reason = string.format(
          'expected minimum value (exclusive) of %s, got %s',
          schema.exclusive_minimum, self)
      return false, SchemaConstraintFailureException(
          path, failure_reason, level + 1)
    end
  end
  if schema.maximum then
    if self >= schema.maximum then
      local failure_reason = string.format(
          'expected minimum value (inclusive) of %s, got %s', schema.maximum, self)
      return false, SchemaConstraintFailureException(
          path, failure_reason, level + 1)
    end
  end
  if schema.exclusive_maximum then
      local failure_reason = string.format(
          'expected minimum value (exclusive) of %s, got %s',
          schema.exclusive_maximum, self)
    if self > schema.exclusive_maximum then
      return false, SchemaConstraintFailureException(
          path, failure_reason, level + 1)
    end
  end
  return true
end

local metatable = {}

function metatable:__call(value)
  if value == nil or value == false then
    return 0
  elseif value == true then
    return 1
  else
    return tonumber(value)
  end
end;

function metatable:__tostring()
  return 'Number'
end;

setmetatable(Number, metatable)

return _M

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local getclass_module = require 'llx.getclass'
local isinstance_module = require 'llx.isinstance'
local table_module = require 'llx.types.Table'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class
local Decorator = decorator.Decorator
local getclass = getclass_module.getclass
local InvalidArgumentException = exceptions.InvalidArgumentException
local InvalidArgumentTypeException = exceptions.InvalidArgumentTypeException
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

function check_returns(expected_types, return_values)
  for i=1, #expected_types do
    check_argument(i, return_values[i], expected_types[i])
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

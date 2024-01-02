-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/getclass'
require 'llx/src/exceptions/invalid_argument_exception'

local function check_argument(index, value, expected_type)
  if expected_type == nil then
    error(InvalidArgumentException(1, Table, getclass(value), 2))
  else
    local correct_type, exception = isinstance(value, expected_type)
    if not correct_type then
      if exception then
        error(InvalidArgumentException(index, exception.what, 4))
      else
        error(InvalidArgumentTypeException(
            index, expected_type, getclass(value), 4))
      end
    end
  end
end

function check_returns(expected_types)
  return function(...)
    local return_values = {...}
    for i=1, #expected_types do
      check_argument(i, return_values[i], expected_types[i])
    end
    return ...
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
  return check_return
end

return check_arguments

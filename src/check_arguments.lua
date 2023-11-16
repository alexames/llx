-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/getclass'
require 'llx/src/exceptions/invalid_argument_exception'

function check_arguments(expected_types)
  local index = 0
  repeat
    index = index + 1
    local name, value = debug.getlocal(2, index)
    local expected_type = expected_types[name]
    if name then
      if expected_type == nil then
        error(InvalidArgumentException(1, Table, getclass(value), 1))
      else
        local correct_type, exception = isinstance(value, expected_type)
        if not correct_type then
          if exception then
            error(InvalidArgumentException(index, exception.what, 3))
          else
            error(InvalidArgumentTypeException(
                index, expected_type, getclass(value), 3))
          end
        end
      end
    end
  until name == nil
end

return check_arguments

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
      elseif not isinstance(value, expected_type) then
        error(InvalidArgumentException(index, expected_type, getclass(value), 3))
      end
    end
  until name == nil
end

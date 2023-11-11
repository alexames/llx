require 'llx/src/class'
require 'llx/src/exceptions'
require 'llx/src/getclass'

local function check_types(location, expected_types, argument_list)
  for index, expected_type in ipairs(expected_types or {}) do
    local value = argument_list[index]
    local correct = isinstance(value, expected_type)
    if not correct then
      error(InvalidArgumentException(index, expected_type, getclass(value)))
    end
  end
end

local function type_check_decorator(underlying_function, expected_types)
  if not expected_types then
    return underlying_function
  end
  local argument_types = expected_types.args
  local return_types = expected_types.returns
  local function type_checker(underlying_function)
    return function(...)
      check_types('argument', argument_types, {...})
      local result = {underlying_function(...)}
      check_types('return', return_types, result)
      return table.unpack(result)
    end
  end
  return type_checker(underlying_function)
end

return type_check_decorator

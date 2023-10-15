require 'ext'
local e = require 'lx/exception'
local try, Exception = e.try, e.Exception
local class, test = table.unpack(require 'lx/class', nil, nil)

local function gettype(o)
  local type = type(o)
  if type == 'nil' then
    return nil_table
  elseif type == 'boolean' then
    return boolean
  elseif type == 'number' then
    return number
  elseif type == 'string' then
    return string
  elseif type == 'table' then
    return getmetatable(o) or table
  elseif type == 'function' then
    return function_table
  elseif type == 'thread' then
    return thread
  elseif type == 'userdata' then
    return getmetatable(o) or userdata
  end
end

local InvalidArgumentException = 
    class 'InvalidArgumentException' : extends(Exception) {
  __init = function(self, argument_index, expected_type, actual_type)
    Exception.__init(
      self,
      string.format(
        'bad argument #%s (%s expected, got %s)',
        argument_index, expected_type, actual_type))
  end
}

local function check_types(location, expected_types, argument_list)
  for index, expected_type in ipairs(expected_types) do
    local value = argument_list[index]
    local correct = expected_type.isinstance(value)
    if not correct then
      error(InvalidArgumentException(index, expected_type, gettype(value)))
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
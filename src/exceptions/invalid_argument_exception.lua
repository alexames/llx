-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local Exception = require 'llx.exceptions.exception' . Exception

local _ENV, _M = environment.create_module_environment()

InvalidArgumentException =
    class 'InvalidArgumentException' : extends(Exception) {
  __init = function(self, argument_index, failure_reason, level)
    local what =
        string.format('bad argument #%s:\n  %s', argument_index, failure_reason)
    Exception.__init(self, what, (level or 1) + 1)
  end,

  __tostring = Exception.__tostring, -- Fix this.
}

-- Names a type (or pre-rendered description) for the mismatch
-- message. String entries are their own name: llx extends the string
-- library, so every Lua string exposes __name == 'String' and the
-- generic branch would render a string-named expected type (e.g.
-- params={'MyClass'}) as 'String' instead of 'MyClass'. This also
-- lets callers pass an already-formatted description (such as
-- "an instance of Animal") for either side.
local function type_name_of(t)
  if type(t) == 'string' then
    return t
  end
  return t and (t.__name or tostring(t)) or 'nil'
end

InvalidArgumentTypeException =
    class 'InvalidArgumentTypeException' : extends(InvalidArgumentException) {
  __init = function(self, argument_index, expected_type, actual_type, level)
    local failure_reason =
        string.format(
          '%s expected, got %s',
          type_name_of(expected_type), type_name_of(actual_type))
    InvalidArgumentException.__init(
        self, argument_index, failure_reason, (level or 1) + 1)
  end,

  __tostring = InvalidArgumentException.__tostring, -- Fix this.
}

return _M

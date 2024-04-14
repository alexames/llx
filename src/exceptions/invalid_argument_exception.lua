-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx/src/class' . class
local environment = require 'llx/src/environment'
local Exception = require 'llx/src/exceptions/exception' . Exception

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

InvalidArgumentTypeException =
    class 'InvalidArgumentTypeException' : extends(InvalidArgumentException) {
  __init = function(self, argument_index, expected_type, actual_type, level)
    local failure_reason =
        string.format('%s expected, got %s', expected_type.__name, actual_type)
    InvalidArgumentException.__init(
        self, argument_index, failure_reason, (level or 1) + 1)
  end,

  __tostring = InvalidArgumentException.__tostring, -- Fix this.
}

return _M

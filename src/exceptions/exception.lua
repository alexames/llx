-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

Exception = class 'Exception' {
  __init = function(self, what, level)
    self.what = what
    self.traceback = debug.traceback('', (level or 1) + 1)
  end,

  --- Returns the short form: "ClassName: what" with no traceback.
  -- Useful for log lines or user-facing error reporting where the
  -- traceback would just be noise. The full tostring() form (with
  -- traceback) remains the default for raw printing.
  message = function(self)
    return self.__name .. ': ' .. self.what
  end,

  __tostring = function(self)
    return self.__name .. ':' .. self.what .. self.traceback
  end,
}

return _M

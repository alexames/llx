-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

Exception = class 'Exception' {
  __init = function(self, what, level)
    self.what = what
    self.traceback = debug.traceback('', (level or 1) + 1)
  end,

  __tostring = function(self)
    return self.__name .. ':' .. self.what .. self.traceback
  end,
}

return _M

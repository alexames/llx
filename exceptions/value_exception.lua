-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx/class' . class
local environment = require 'llx/environment'
local Exception = require 'llx/exceptions/exception' . Exception

local _ENV, _M = environment.create_module_environment()

ValueException =
    class 'InvalidArgumentException' : extends(Exception) {
  __init = function(self, what, level)
    Exception.__init(self, what, (level or 1) + 1)
  end,
}

return _M

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local Exception = require 'llx.exceptions.exception' . Exception

local _ENV, _M = environment.create_module_environment()

--- RuntimeError: Raised when an error is detected that doesn't fall in any of the other categories
RuntimeError = class 'RuntimeError' : extends(Exception) {}

return _M

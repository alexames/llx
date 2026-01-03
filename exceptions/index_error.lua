-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local Exception = require 'llx.exceptions.exception' . Exception

local _ENV, _M = environment.create_module_environment()

--- IndexError: Raised when a sequence subscript is out of range
IndexError = class 'IndexError' : extends(Exception) {}

return _M

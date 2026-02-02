-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local Exception = require 'llx.exceptions.exception' . Exception

local _ENV, _M = environment.create_module_environment()

--- TypeError: Raised when an operation receives an argument of inappropriate type
TypeError = class 'TypeError' : extends(Exception) {}

return _M

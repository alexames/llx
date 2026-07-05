-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local Exception = require 'llx.exceptions.exception' . Exception

local _ENV, _M = environment.create_module_environment()

--- AttributeError: Raised when an attribute reference or assignment
-- fails, such as assigning to a field of an immutable record.
AttributeError = class 'AttributeError' : extends(Exception) {}

return _M

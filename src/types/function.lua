-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'

local _ENV, _M = environment.create_module_environment()

Function = {}

Function.__name = 'function';

function Function:__isinstance(value)
  return type(value) == 'function'
end

local metatable = {}

function metatable:__tostring()
  return 'Function'
end

setmetatable(Function, metatable)

return _M

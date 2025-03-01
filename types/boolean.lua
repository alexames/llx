-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

Boolean = {}

Boolean.__name = 'Boolean'

function Boolean:__isinstance(value)
  return type(value) == 'boolean'
end

function Boolean:__call(v)
  return v ~= nil and v ~= false
end

function Boolean.__tostring()
  return 'Boolean'
end

return _M

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'

local _ENV, _M = environment.create_module_environment()

Userdata = {}

Userdata.__name = 'Userdata'

function Userdata:__isinstance(v)
  return type(v) == 'userdata'
end

local metatable = {}

function metatable:__tostring()
  return 'Userdata'
end

setmetatable(Userdata, metatable)

return _M

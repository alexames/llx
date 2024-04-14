-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'

local _ENV, _M = environment.create_module_environment()

Nil = {}

Nil.__name = 'nil';

function Nil:__isinstance(v)
  return type(v) == 'nil'
end

local metatable = {}

function metatable:__tostring() return 'Nil' end;

setmetatable(Nil, metatable)

return _M

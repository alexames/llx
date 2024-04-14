-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'
local Number = require 'llx/src/types/number' . Number

local _ENV, _M = environment.create_module_environment()

Float = {}

Float.__name = 'Float'

function Float:__isinstance(v)
  return math.type(v) == 'float'
end

Float.__validate = Number.__validate

local metatable = {}

function metatable:__call( v)
  if v == nil or v == false then
    return 0.0
  elseif v == true then
    return 1.0
  else
    return tofloat(v)
  end
end

function metatable:__tostring() 
  return 'Float'
end

setmetatable(Float, metatable)

return _M

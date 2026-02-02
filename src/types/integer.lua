-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'
local Number = require 'llx.types.number' . Number

local _ENV, _M = environment.create_module_environment()

Integer = {}

Integer.__name = 'Integer'

function Integer:__isinstance(v)
  return math.type(v) == 'integer'
end

Integer.__validate = Number.__validate

local metatable = {}

function metatable:__call(v)
  if v == nil or v == false then
    return 0
  elseif v == true then
    return 1
  else
    return tointeger(v)
  end
end

function metatable:__tostring()
  return 'Integer'
end

setmetatable(Integer, metatable)

return _M

-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

local Number = require 'llx/src/types/number'

local Integer = {}

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

return setmetatable(Integer, metatable)

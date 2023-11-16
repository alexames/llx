-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

local Number = require 'llx/src/types/number'

local Float = {}

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

return setmetatable(Float, metatable)

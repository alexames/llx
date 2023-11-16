-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

local Number = {}

Number.__name = 'Number'

function Number:__isinstance(value)
  return type(value) == 'number'
end

local metatable = {}

function metatable:__call(value)
  if value == nil or value == false then
    return 0
  elseif value == true then
    return 1
  else
    return tonumber(value)
  end
end;

function metatable:__tostring()
  return 'Number'
end;

return setmetatable(Number, metatable)

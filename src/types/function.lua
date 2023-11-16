-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

local Function = {}

Function.__name = 'function';

function Function:__isinstance(value)
  return type(value) == 'function'
end

local metatable = {}

function metatable:__tostring()
  return 'Function'
end

return setmetatable(Function, metatable)

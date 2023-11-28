-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

local Nil = {}

Nil.__name = 'nil';

function Nil:__isinstance(v)
  return type(v) == 'nil'
end

local metatable = {}

function metatable:__tostring() return 'Nil' end;

return setmetatable(Nil, metatable)

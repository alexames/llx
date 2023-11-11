local Nil = {}

Nil.__name = 'nil';

function Nil:__isinstance(v)
  return type(v) == 'nil'
end

local metatable = {}

function metatable:__tostring() return 'Nil' end;

return Nil

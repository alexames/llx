local Userdata = {}

Userdata.__name = 'Userdata'

function Userdata:__isinstance(v)
  return type(v) == 'userdata'
end

local metatable = {}

function metatable:__tostring()
  return 'Userdata'
end

return setmetatable(Userdata, metatable)

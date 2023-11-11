local Thread = {}

Thread.__name = 'Thread'

function Thread:__isinstance(v)
  return type(v) == 'thread'
end

local metatable = {}

function metatable:__tostring()
  return 'Thread'
end

return setmetatable(Thread, metatable)

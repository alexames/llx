local Boolean = {}

Boolean.__name = 'Boolean'

function Boolean:__isinstance(value)
  return type(value) == 'boolean'
end

local metatable = {}

function Boolean:__call(v)
  return v ~= nil and v ~= false
end

function Boolean.__tostring()
  return 'Boolean'
end

return Boolean
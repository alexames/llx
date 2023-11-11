require 'llx/src/core'

function isinstance(value, type)
  local __isinstance = type.__isinstance
  return __isinstance and __isinstance(type, value)
end

return isinstance

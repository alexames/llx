-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/core'

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function isinstance(value, type)
  local __isinstance = type.__isinstance
  return __isinstance and __isinstance(type, value)
end

return isinstance

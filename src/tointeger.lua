-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/core'

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function tointeger(value)
  local __tointeger = getmetafield(value, '__tointeger')
  return __tointeger and __tointeger(value) or math.floor(value)
end

return tointeger

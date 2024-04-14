-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'
local getmetafield = require 'llx/src/core' . getmetafield

local _ENV, _M = environment.create_module_environment()

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function tointeger(value)
  local __tointeger = getmetafield(value, '__tointeger')
  return __tointeger and __tointeger(value) or math.floor(value)
end

return _M

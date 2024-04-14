-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'
local core = require 'llx/core'

local _ENV, _M = environment.create_module_environment()

local getmetafield =core.getmetafield

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function tointeger(value)
  local __tointeger = getmetafield(value, '__tointeger')
  return __tointeger and __tointeger(value) or math.floor(value)
end

return _M

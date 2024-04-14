-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/environment'

local _ENV, _M = environment.create_module_environment()

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function isinstance(value, type)
  local __isinstance = type.__isinstance
  if __isinstance then
    return __isinstance(type, value)
  end
  return false
end

return _M

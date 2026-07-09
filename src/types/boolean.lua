-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

Boolean = {}

Boolean.__name = 'Boolean'

function Boolean:__isinstance(value)
  return type(value) == 'boolean'
end

function Boolean:__call(v)
  return v ~= nil and v ~= false
end

function Boolean.__tostring()
  return 'Boolean'
end

-- __call and __tostring above are metamethods, so they only take
-- effect through a metatable. Without this, tostring(Boolean) falls
-- back to the raw table address, which breaks any matcher that embeds
-- Boolean in its construction-time name (e.g. Union{..., Boolean}
-- concatenates member names and requires __tostring).
setmetatable(Boolean, {
  __call = Boolean.__call,
  __tostring = Boolean.__tostring,
})

return _M

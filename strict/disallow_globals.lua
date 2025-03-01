-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local function disallow_writes(t, k, v)
  local error_string = string.format(
    'writes disallowed (attempted to write to [%s] = %s)', tostring(k),
    tostring(v))
  error(error_string, 2)
end

function lock_global_table()
  local old_global_metatable = getmetatable(_G)
  local new_global_metatable = old_global_metatable or {}

  local old_global_newindex = new_global_metatable.__newindex
  local new_global_newindex = disallow_writes

  new_global_metatable.__newindex = new_global_newindex
  setmetatable(_G, new_global_metatable)

  return setmetatable({}, {
    __close = function()
      new_global_metatable.__newindex = old_global_newindex
      setmetatable(_G, old_global_metatable)
    end,
  })
end

return _M

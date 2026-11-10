-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local compat = require 'llx.compat'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local function disallow_writes(t, k, v)
  local error_string = compat.format(
    'writes disallowed (attempted to write to [%s] = %s)', tostring(k),
    tostring(v))
  error(error_string, 2)
end

-- A lock whose __close runs `release`.
local function lock_released_by(release)
  return setmetatable({}, {
    __close = function()
      release()
    end,
  })
end

--- Makes a write of a new global name raise until the returned lock is
-- closed, so that an accidental global assignment fails where it is
-- made.
--
-- The guard is a `__newindex` on `_G`'s metatable. A host that has
-- already set one, or protected that metatable with a `__metatable`
-- field, has already decided what a global write does: its metatable is
-- left as it is, and closing the returned lock does nothing.
-- @return A lock whose `__close` metamethod removes the guard. Lua 5.4+
--   calls it for a `<close>` variable; on earlier versions call
--   `getmetatable(lock).__close(lock)`.
function lock_global_table()
  local globals = _G
  local metatable = getmetatable(globals)
  if metatable == nil then
    setmetatable(globals, {__newindex = disallow_writes})
    return lock_released_by(function()
      setmetatable(globals, nil)
    end)
  end
  -- setmetatable to the metatable globals already has changes nothing,
  -- unless that metatable is protected, which makes it raise.
  if type(metatable) ~= 'table'
      or rawget(metatable, '__newindex') ~= nil
      or not pcall(setmetatable, globals, metatable) then
    return lock_released_by(function() end)
  end
  rawset(metatable, '__newindex', disallow_writes)
  return lock_released_by(function()
    rawset(metatable, '__newindex', nil)
  end)
end

return _M

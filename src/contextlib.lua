-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Context managers.
--
-- Lua 5.4 introduced to-be-closed variables (<close>), which run
-- a __close metamethod when the variable's scope ends — even on
-- error. That's powerful but requires the local-declaration
-- syntax and can't be passed across function boundaries. This
-- module provides a callable-style wrapper that works with any
-- resource that has either __close (5.4 native) or a :close
-- method (older idiom).
-- @module llx.contextlib

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

--- Picks a cleanup function for a resource.
-- Prefers __close on the metatable (Lua 5.4 to-be-closed
-- convention), falls back to a :close method on the resource,
-- and finally to nothing.
local function cleanup_function(resource)
  if type(resource) == 'table' or type(resource) == 'userdata' then
    local mt = debug.getmetatable(resource)
    if mt and type(mt.__close) == 'function' then
      return function(err) return mt.__close(resource, err) end
    end
  end
  if type(resource) == 'table'
      and type(resource.close) == 'function' then
    return function() return resource.close(resource) end
  end
  if type(resource) == 'userdata'
      and io.type and io.type(resource) ~= nil then
    -- Lua 5.4 file handles already have __close, but some 5.3
    -- back-compat shims expose only :close. Be defensive.
    return function() return resource:close() end
  end
  return nil
end

--- Runs fn(resource), guaranteeing that the resource is closed
-- afterward regardless of whether fn returned normally or raised.
-- If fn raised, the original error is re-raised after cleanup.
-- @param resource A value to manage. Must have either a __close
--   metamethod or a :close method, otherwise no cleanup runs.
-- @param fn function(resource) -> any
-- @return Whatever fn returned (all return values pass through).
function with(resource, fn)
  if type(fn) ~= 'function' then
    error('with: fn must be a function', 2)
  end
  local results = table.pack(pcall(fn, resource))
  local ok = results[1]
  local err = ok and nil or results[2]

  local close = cleanup_function(resource)
  if close then
    -- Cleanup errors are reported via stderr but do not mask the
    -- original error. If fn succeeded and cleanup raised, the
    -- cleanup error is re-raised; this matches Python's behavior
    -- where __exit__ exceptions during a non-exceptional flow
    -- propagate.
    local cleanup_ok, cleanup_err = pcall(close, err)
    if ok and not cleanup_ok then
      error(cleanup_err, 2)
    end
  end

  if not ok then error(err, 0) end
  return table.unpack(results, 2, results.n)
end

--- Wraps a value so its `close` method is called via __close
-- when used as a <close> variable. Useful when a library exposes
-- :close but doesn't set the __close metamethod (5.4+ requires
-- __close to be a metamethod, not a regular method).
-- @param resource A value with a :close method
-- @return A wrapped resource ready for `local x <close> = ...`
function closing(resource)
  if type(resource) ~= 'table'
      or type(resource.close) ~= 'function' then
    error('closing: resource must be a table with a :close method', 2)
  end
  return setmetatable({_inner = resource}, {
    __index = resource,
    __close = function(self)
      self._inner:close()
    end,
  })
end

return _M

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local compat = require 'llx.compat'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local proxy_metatable

local function tovalue(v)
  return getmetatable(v) == proxy_metatable and rawget(v, 1) or v
end

-- One metatable shared by every proxy: Lua 5.1 compares two tables
-- through __eq, __lt or __le only when both metatables hold the same
-- function, so a metatable per proxy would make proxy < proxy raise.
proxy_metatable = compat.add_integer_operator_metamethods({
  __add      = function(a, b)    return tovalue(a) +  tovalue(b) end;
  __sub      = function(a, b)    return tovalue(a) -  tovalue(b) end;
  __mul      = function(a, b)    return tovalue(a) *  tovalue(b) end;
  __div      = function(a, b)    return tovalue(a) /  tovalue(b) end;
  __mod      = function(a, b)    return tovalue(a) %  tovalue(b) end;
  __pow      = function(a, b)    return tovalue(a) ^  tovalue(b) end;
  __unm      = function(a)       return -tovalue(a)              end;
  __concat   = function(a, b)    return tovalue(a) .. tovalue(b) end;
  __len      = function(t)       return #tovalue(t)              end;
  __eq       = function(a, b)    return tovalue(a) == tovalue(b) end;
  __lt       = function(a, b)    return tovalue(a) <  tovalue(b) end;
  __le       = function(a, b)    return tovalue(a) <= tovalue(b) end;
  __index    = function(t, k)    return tovalue(t)[k]            end;
  __newindex = function(t, k, v)        tovalue(t)[k] = v        end;
  __call     = function(t, ...)  return tovalue(t)(...)          end;
  __tostring = function(t)       return tostring(tovalue(t))     end;
}, tovalue)

--- Creates a proxy object that wraps a value and forwards operations.
-- @param value The value to wrap in a proxy
-- @return A proxy object that forwards all operations to the wrapped value
function Proxy(value)
  return setmetatable({value}, proxy_metatable)
end

--- Sets the value wrapped by a proxy object.
-- @param proxy The proxy object
-- @param value The new value to store in the proxy
function set_proxy_value(proxy, value)
  rawset(proxy, 1, value)
end

--- Extracts the value wrapped by a proxy object.
-- @param proxy The proxy object
-- @return The value stored in the proxy
function extract_proxy_value(proxy)
  return rawget(proxy, 1)
end

return _M

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'

local _ENV, _M = environment.create_module_environment()

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function Proxy(value)
  local proxy_object = {value}
  local function tovalue(v)
    return rawequal(v, proxy_object) and rawget(v, 1) or v
  end
  return setmetatable(proxy_object, {
    __add      = function(a, b)    return tovalue(a) +  tovalue(b) end;
    __sub      = function(a, b)    return tovalue(a) -  tovalue(b) end;
    __mul      = function(a, b)    return tovalue(a) *  tovalue(b) end;
    __div      = function(a, b)    return tovalue(a) /  tovalue(b) end;
    __mod      = function(a, b)    return tovalue(a) %  tovalue(b) end;
    __pow      = function(a, b)    return tovalue(a) ^  tovalue(b) end;
    __unm      = function(a)       return -tovalue(a)              end;
    __idiv     = function(a, b)    return tovalue(a) // tovalue(b) end;
    __band     = function(a, b)    return tovalue(a) &  tovalue(b) end;
    __bor      = function(a, b)    return tovalue(a) |  tovalue(b) end;
    __bxor     = function(a, b)    return tovalue(a) ~  tovalue(b) end;
    __bnot     = function(a, b)    return ~tovalue(a)              end;
    __shl      = function(a, b)    return tovalue(a) << tovalue(b) end;
    __shr      = function(a, b)    return tovalue(a) >> tovalue(b) end;
    __concat   = function(a, b)    return tovalue(a) .. tovalue(b) end;
    __len      = function(t)       return #tovalue(t)              end;
    __eq       = function(a, b)    return tovalue(a) == tovalue(b) end;
    __lt       = function(a, b)    return tovalue(a) <  tovalue(b) end;
    __le       = function(a, b)    return tovalue(a) <= tovalue(b) end;
    __index    = function(t, k)    return tovalue(t)[k]            end;
    __newindex = function(t, k, v)        tovalue(t)[k] = v        end;
    __call     = function(t, ...)  return tovalue(t)(...)          end;
    __tostring = function(t)       return tostring(tovalue(t))     end;
  })
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function set_proxy_value(proxy, value)
  rawset(proxy, 1, value)
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function extract_proxy_value(proxy)
  return rawget(proxy, 1)
end

return _M

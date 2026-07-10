-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'
local types = require 'llx.types'

local _ENV, _M = environment.create_module_environment()

function getclass(value)
  local type = type(value)
  if type == 'nil' then
    return types.Nil
  elseif type == 'boolean' then
    return types.Boolean
  elseif type == 'number' then
    return types.Number
  elseif type == 'string' then
    return types.String
  elseif type == 'table' then
    return getmetatable(value) or types.Table
  elseif type == 'function' then
    return types.Function
  elseif type == 'thread' then
    return types.Thread
  elseif type == 'userdata' then
    return getmetatable(value) or types.Userdata
  end
end

--- Returns true when value is a class object produced by llx.class
-- (a class table proxy), as opposed to an instance, a plain table, or
-- a non-table. Two facts uniquely identify a class proxy (see the
-- implementation notes in src/class.lua):
--
-- - getmetatable(proxy) returns the proxy itself (the proxy metatable
--   sets __metatable to the proxy), whereas getmetatable(instance)
--   returns the instance's class proxy, never the instance, and a
--   plain table's metatable (if any) is some other table.
-- - The proxy's __index resolves against the internal class table,
--   where __is_llx_class is rawset to true on every class; instances
--   would also inherit the flag, but the metatable check above has
--   already excluded them.
function is_class_object(value)
  return type(value) == 'table'
     and rawequal(getmetatable(value), value)
     and value.__is_llx_class == true
end

--- Describes a value for diagnostics ("expected X, got <this>").
-- Scalars include their payload ("number 42", "string 'id'"); class
-- objects and class instances are called out explicitly ("the class
-- Animal", "an instance of Animal") because a bare "table" -- or a
-- bare class name -- is ambiguous between the class, an instance of
-- it, and an unrelated table. Everything else reports its raw Lua
-- type.
function describe_value(value)
  local value_type = type(value)
  if value_type == 'number' or value_type == 'boolean' then
    return value_type .. ' ' .. tostring(value)
  end
  if value_type == 'string' then
    return "string '" .. value .. "'"
  end
  if value_type == 'table' then
    if is_class_object(value) then
      return 'the class ' .. (value.__name or tostring(value))
    end
    local metatable = getmetatable(value)
    if is_class_object(metatable) then
      return 'an instance of '
          .. (metatable.__name or tostring(metatable))
    end
  end
  return value_type
end

return _M

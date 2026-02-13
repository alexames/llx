--- Bidirectional enum type for bytecode parsing.
-- Creates enum tables that support both forward (integer to name) and
-- reverse (name to integer) lookup. Each entry stores both a name and
-- a numeric value. Used to define opcodes and type tags.
-- @module llx.bytecode.lua55.enum

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local enum_metatable = {
  --- Insert a key-value pair into the enum, creating bidirectional mappings.
  -- @param k the numeric key
  -- @param v the string name
  insert = function(self, k, v)
    local enum_object = {name=v, value=k}
    if self[k] == nil then
      rawset(self, k, enum_object)
    end
    if self[v] == nil then
      rawset(self, v, enum_object)
    end
  end,

  __newindex = function(self, k, v)
    self:insert(k, v)
  end
}

enum_metatable.__index = enum_metatable

--- Create a new bidirectional enum from a table of key-value pairs.
-- Numeric keys map to string names, and string names map back to
-- the corresponding enum object containing both name and value fields.
-- @param t a table mapping integers to string names
-- @return a new enum table with bidirectional lookup
function enum(t)
  local result = setmetatable({}, enum_metatable)
  for k, v in pairs(t) do
    result[k] = v
  end
  return result
end

return _M

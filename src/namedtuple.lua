-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Factory for named, positional, immutable tuple classes.
-- namedtuple('Point', {'x', 'y'}) returns a class whose instances
-- have positional indexing AND named-field access, with structural
-- equality and value-based hashing. Mirrors Python's
-- collections.namedtuple.
-- @module llx.namedtuple

local class_module = require 'llx.class'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class

--- Creates a new namedtuple class.
-- @param name The class name (string).
-- @param fields A list of field names (strings).
-- @return A class. Calling it with positional values creates an
--   instance.
function namedtuple(name, fields)
  if type(name) ~= 'string' then
    error('namedtuple: name must be a string', 2)
  end
  if type(fields) ~= 'table' then
    error('namedtuple: fields must be a table of strings', 2)
  end
  local n_fields = #fields
  -- Map name -> position for O(1) named-field lookup.
  local field_index = {}
  for i, fname in ipairs(fields) do
    if type(fname) ~= 'string' then
      error('namedtuple: field names must be strings', 2)
    end
    if field_index[fname] then
      error('namedtuple: duplicate field name "' .. fname .. '"', 2)
    end
    field_index[fname] = i
  end

  local cls
  cls = class(name) {
    __new = function(...)
      local args = table.pack(...)
      if args.n ~= n_fields then
        error(string.format(
          '%s expects %d argument%s, got %d',
          name,
          n_fields,
          n_fields == 1 and '' or 's',
          args.n), 3)
      end
      -- Store values in a sub-table so __newindex fires on every
      -- attempted write to the instance (Lua's __newindex only
      -- fires for keys that don't already exist on the instance).
      local values = {}
      for i = 1, n_fields do
        values[i] = args[i]
      end
      return {__values = values}
    end,

    __init = function(self) end,

    __index = function(self, key)
      if type(key) == 'number' then
        return self.__values[key]
      end
      if type(key) == 'string' then
        local i = field_index[key]
        if i then return self.__values[i] end
      end
      return cls.__defaultindex(self, key)
    end,

    __newindex = function()
      error(name .. ' is immutable', 2)
    end,

    __len = function() return n_fields end,

    __eq = function(self, other)
      if #self ~= #other then return false end
      local sv, ov = self.__values, other.__values
      for i = 1, n_fields do
        if sv[i] ~= ov[i] then return false end
      end
      return true
    end,

    __hash = function(self, result)
      local hash = require 'llx.hash'
      result = hash.hash_string(name, result)
      local v = self.__values
      for i = 1, n_fields do
        result = hash.hash_value(v[i], result)
      end
      return result
    end,

    __tostring = function(self)
      local parts = {}
      local v = self.__values
      for i = 1, n_fields do
        parts[i] = fields[i] .. '=' .. tostring(v[i])
      end
      return name .. '(' .. table.concat(parts, ', ') .. ')'
    end,

    -- Returns the field names in order for introspection.
    fields = function(self)
      local copy = {}
      for i = 1, n_fields do copy[i] = fields[i] end
      return copy
    end,

    -- Returns a plain Lua table mapping name -> value.
    as_table = function(self)
      local t = {}
      local v = self.__values
      for i = 1, n_fields do
        t[fields[i]] = v[i]
      end
      return t
    end,
  }

  return cls
end

return _M

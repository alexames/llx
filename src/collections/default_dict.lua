-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Map with a factory-backed default for missing keys.
-- The factory is called the first time a key is read with :get();
-- subsequent reads return the stored value. Set and delete behave
-- like a plain map. Use cases include "table of lists" or "table
-- of counters" patterns where the surrounding code shouldn't have
-- to handle the first-use case manually.
-- @module llx.collections.default_dict

local class = require 'llx.class' . class
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

DefaultDict = class 'DefaultDict' {
  __init = function(self, factory)
    if type(factory) ~= 'function' then
      error('DefaultDict requires a factory function', 2)
    end
    rawset(self, '_factory', factory)
    rawset(self, '_data', {})
  end,

  -- Returns the value at key, creating it via the factory if absent.
  -- The created value is stored, so subsequent reads return the
  -- same object.
  get = function(self, key)
    local v = self._data[key]
    if v == nil then
      v = self._factory(key)
      self._data[key] = v
    end
    return v
  end,

  -- Returns the value at key without triggering the factory.
  -- nil if absent.
  peek = function(self, key)
    return self._data[key]
  end,

  set = function(self, key, value)
    self._data[key] = value
    return self
  end,

  delete = function(self, key)
    self._data[key] = nil
    return self
  end,

  -- True iff the key has a stored value. Does not trigger the
  -- factory.
  contains = function(self, key)
    return self._data[key] ~= nil
  end,

  keys = function(self)
    local result = {}
    for k in pairs(self._data) do
      result[#result + 1] = k
    end
    return result
  end,

  values = function(self)
    local result = {}
    for _, v in pairs(self._data) do
      result[#result + 1] = v
    end
    return result
  end,

  clear = function(self)
    self._data = {}
    return self
  end,

  __len = function(self)
    local n = 0
    for _ in pairs(self._data) do n = n + 1 end
    return n
  end,

  __pairs = function(self)
    return pairs(self._data)
  end,

  -- Equal iff same set of keys map to same values. Factory
  -- functions do not participate.
  __eq = function(self, other)
    for k, v in pairs(self._data) do
      if other._data[k] ~= v then return false end
    end
    for k, v in pairs(other._data) do
      if self._data[k] ~= v then return false end
    end
    return true
  end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    local keys = {}
    for k in pairs(self._data) do
      keys[#keys + 1] = k
    end
    table.sort(keys, function(a, b)
      return hash.hash(a) < hash.hash(b)
    end)
    for _, k in ipairs(keys) do
      result = hash.hash_value(k, result)
      result = hash.hash_value(self._data[k], result)
    end
    return result
  end,

  __tostring = function(self)
    local parts = {}
    for k, v in pairs(self._data) do
      parts[#parts + 1] =
        tostring(k) .. '=' .. tostring(v)
    end
    table.sort(parts)
    return 'DefaultDict{' .. table.concat(parts, ', ') .. '}'
  end,
}

return _M

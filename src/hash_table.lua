-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class_module = require 'llx.class'
local environment = require 'llx.environment'
local hash = require 'llx.hash'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class

--- A hash table implementation that hashes keys for value-based lookup.
--
-- By hashing the keys, any type that has a __hash metamethod can be used as a
-- key, which is useful for things like Tuples where you may have different
-- Lua objects that contain the same values, and thus hash the same.
-- Keys that hash to the same value are treated as the same key (hash-as-identity).
HashTable = class 'HashTable' {
  __init = function(self)
  end,

  __newindex = function(self, k, v)
    local hashed_key = hash.hash(k)
    if v ~= nil then
      rawset(self, hashed_key, {key=k, value=v})
    else
      rawset(self, hashed_key, nil)
    end
  end,

  __index = function(self, k)
    local hashed_key = hash.hash(k)
    local entry = rawget(self, hashed_key)
    if entry then
      return entry.value
    end
    return HashTable.__defaultindex(self, k)
  end,

  __pairs = function(self)
    local hashed_key = nil
    return function()
      hashed_key = next(self, hashed_key)
      if hashed_key == nil then
        return nil
      end
      local entry = rawget(self, hashed_key)
      return entry.key, entry.value
    end
  end,
}

return _M

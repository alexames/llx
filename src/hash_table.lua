-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx/src/class' . class
local environment = require 'llx/src/environment'
local decorator = require 'llx/src/decorator'
local hash = require 'llx/src/hash'
local tuple = require 'llx/src/tuple'

local _ENV, _M = environment.create_module_environment()

--- A dumb hash table implementation that hashes the keys but not much else.
--
-- By hashing the keys, any type that has a __hash metamethod can be used as a
-- key, which is useful for things like Tuples where you may have different
-- Lua objects that contain the same values, and thus hash the same.
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
    local entry = self[hashed_key]
    return entry and entry.value or HashTable.__defaultindex(k, v)
  end,

  __pairs = function(self)
    local hashed_key
    return function()
      local hashed_key = next(self, hashed_key)
      local slot = rawget(self, hashed_key)
      if slot then return slot.key, slot.value end
    end
  end,
}

return _M

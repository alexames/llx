-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class_module = require 'llx.class'
local environment = require 'llx.environment'
local hash = require 'llx.hash'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class
local core = require 'llx.core'

--- Value-based key equality for hash table lookups.
-- Uses == for types with __eq or primitives, and falls
-- back to hash comparison for plain tables (which lack
-- __eq but are hashed by content).
local function _keys_equal(a, b)
  if a == b then return true end
  if type(a) == 'table' and type(b) == 'table'
      and not core.getmetafield(a, '__eq')
      and not core.getmetafield(b, '__eq') then
    return hash.hash(a) == hash.hash(b)
  end
  return false
end

--- A hash table implementation that hashes keys for
--- value-based lookup.
--
-- By hashing the keys, any type that has a __hash metamethod
-- can be used as a key, which is useful for things like
-- Tuples where you may have different Lua objects that
-- contain the same values, and thus hash the same.
-- Collisions are resolved by chaining: each bucket holds a
-- list of {key, value} entries that are searched by equality.
HashTable = class 'HashTable' {
  __init = function(self)
  end,

  __newindex = function(self, k, v)
    local hashed_key = hash.hash(k)
    local bucket = rawget(self, hashed_key)
    if v ~= nil then
      if bucket then
        for i = 1, #bucket do
          if _keys_equal(bucket[i].key, k) then
            bucket[i].value = v
            return
          end
        end
        bucket[#bucket + 1] = {key = k, value = v}
      else
        rawset(self, hashed_key, {{key = k, value = v}})
      end
    else
      if bucket then
        for i = 1, #bucket do
          if _keys_equal(bucket[i].key, k) then
            table.remove(bucket, i)
            if #bucket == 0 then
              rawset(self, hashed_key, nil)
            end
            return
          end
        end
      end
    end
  end,

  __index = function(self, k)
    local hashed_key = hash.hash(k)
    local bucket = rawget(self, hashed_key)
    if bucket then
      for i = 1, #bucket do
        if _keys_equal(bucket[i].key, k) then
          return bucket[i].value
        end
      end
    end
    return HashTable.__defaultindex(self, k)
  end,

  __pairs = function(self)
    local hashed_key = nil
    local bucket_index = 0
    return function()
      while true do
        if hashed_key ~= nil then
          local bucket = rawget(self, hashed_key)
          if bucket then
            bucket_index = bucket_index + 1
            if bucket_index <= #bucket then
              local entry = bucket[bucket_index]
              return entry.key, entry.value
            end
          end
        end
        hashed_key = next(self, hashed_key)
        bucket_index = 0
        if hashed_key == nil then
          return nil
        end
      end
    end
  end,
}

return _M

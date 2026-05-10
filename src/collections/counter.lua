-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Frequency map. Counts occurrences of values in a sequence and
-- supports addition (merge by sum) and subtraction (clamped at 0).
-- Counts are accessed via :get(key) rather than indexing, so method
-- names never collide with user keys.
-- @module llx.collections.counter

local class = require 'llx.class' . class
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

Counter = class 'Counter' {
  __init = function(self, source)
    rawset(self, '_counts', {})
    if source == nil then return end
    local counts = self._counts
    if type(source) == 'function' then
      -- Iterator: count each yielded value.
      for _, v in source do
        counts[v] = (counts[v] or 0) + 1
      end
    elseif type(source) == 'table' then
      -- Either a sequence (treated as items to count) or a map
      -- (treated as key->count pairs). Heuristic: if [1] is set
      -- and there are no non-integer keys, treat as a sequence.
      local is_sequence = source[1] ~= nil
      if is_sequence then
        for _, k in ipairs(source) do
          counts[k] = (counts[k] or 0) + 1
        end
      else
        for k, v in pairs(source) do
          if type(v) ~= 'number' then
            error('Counter map values must be numbers', 2)
          end
          counts[k] = v
        end
      end
    end
  end,

  get = function(self, key)
    return self._counts[key] or 0
  end,

  increment = function(self, key, n)
    n = n or 1
    self._counts[key] = (self._counts[key] or 0) + n
    return self
  end,

  decrement = function(self, key, n)
    return self:increment(key, -(n or 1))
  end,

  set = function(self, key, value)
    self._counts[key] = value
    return self
  end,

  delete = function(self, key)
    self._counts[key] = nil
    return self
  end,

  contains = function(self, key)
    local c = self._counts[key]
    return c ~= nil and c > 0
  end,

  total = function(self)
    local sum = 0
    for _, v in pairs(self._counts) do
      sum = sum + v
    end
    return sum
  end,

  -- Returns up to n items as a list of {key, count} pairs in
  -- descending count order. n=nil returns all items.
  most_common = function(self, n)
    local items = {}
    for k, v in pairs(self._counts) do
      items[#items + 1] = {k, v}
    end
    table.sort(items, function(a, b) return a[2] > b[2] end)
    if n then
      while #items > n do items[#items] = nil end
    end
    return items
  end,

  -- Iterator that yields each key once per count. Mirrors
  -- Python's Counter.elements().
  elements = function(self)
    local key = nil
    local remaining = 0
    local index = 0
    local counts = self._counts
    return function()
      while remaining <= 0 do
        local k = next(counts, key)
        if k == nil then return nil end
        key = k
        remaining = counts[k]
      end
      remaining = remaining - 1
      index = index + 1
      return index, key
    end
  end,

  keys = function(self)
    local result = {}
    for k, _ in pairs(self._counts) do
      result[#result + 1] = k
    end
    return result
  end,

  __len = function(self)
    local n = 0
    for _ in pairs(self._counts) do n = n + 1 end
    return n
  end,

  __eq = function(self, other)
    -- Equal if the same set of keys map to the same counts.
    -- Counts of zero are allowed and must match.
    for k, v in pairs(self._counts) do
      if (other._counts[k] or 0) ~= v then return false end
    end
    for k, v in pairs(other._counts) do
      if (self._counts[k] or 0) ~= v then return false end
    end
    return true
  end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    -- Hash by sorted key list. Sort keys by their hash so the
    -- order is deterministic across runs without requiring a
    -- total order on user keys.
    local keys = {}
    for k in pairs(self._counts) do keys[#keys + 1] = k end
    table.sort(keys, function(a, b)
      return hash.hash(a) < hash.hash(b)
    end)
    for _, k in ipairs(keys) do
      result = hash.hash_value(k, result)
      result = hash.hash_value(self._counts[k], result)
    end
    return result
  end,

  __tostring = function(self)
    local parts = {}
    for k, v in pairs(self._counts) do
      parts[#parts + 1] = tostring(k) .. '=' .. tostring(v)
    end
    table.sort(parts)
    return 'Counter{' .. table.concat(parts, ', ') .. '}'
  end,

  -- Merge two counters by summing counts.
  __add = function(self, other)
    local result = Counter()
    for k, v in pairs(self._counts) do
      result._counts[k] = v
    end
    for k, v in pairs(other._counts) do
      result._counts[k] = (result._counts[k] or 0) + v
    end
    return result
  end,

  -- Subtract counts. Negative results are clamped to 0 (matching
  -- Python's Counter subtract behavior with negative-clamping).
  __sub = function(self, other)
    local result = Counter()
    for k, v in pairs(self._counts) do
      local diff = v - (other._counts[k] or 0)
      if diff > 0 then result._counts[k] = diff end
    end
    return result
  end,
}

return _M

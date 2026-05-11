-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Chainable iterator wrapper.
--
-- Most functions in llx.functional take (function, sequence) or
-- (sequence, function) and return either an iterator or a List.
-- Composing them reads inside-out:
--
--     local out = f.collect(f.filter(p, f.map(g, seq)))
--
-- Seq lets you read top-to-bottom and chain operations with
-- method syntax:
--
--     local out = Seq(seq):map(g):filter(p):collect()
--
-- Transformations are lazy where possible: map, filter, take,
-- drop, take_while, drop_while, flat_map, distinct, enumerate
-- each return a new Seq backed by a generator that pulls from
-- the previous Seq on demand. Terminators (collect, to_list,
-- for_each, reduce, count, first, last, any, all, none, find,
-- sum, product, min, max) consume the iterator and produce a
-- value.
--
-- Constructor accepts an iterator function, a List (anything
-- callable as a Lua iterator), or a plain sequence-shaped table
-- (iterated via ipairs).
-- @module llx.seq

local class_module = require 'llx.class'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class

--- Coerce any supported source into a callable iterator that
-- yields (control, value).
local function to_iterator(source)
  if type(source) == 'function' then return source end
  if type(source) == 'table' then
    local mt = getmetatable(source)
    if mt and type(mt.__call) == 'function' then
      -- Callable table (e.g. List, Deque). Use it directly.
      return source
    end
    -- Plain sequence-shaped table: iterate via ipairs.
    local i = 0
    return function()
      i = i + 1
      if source[i] == nil then return nil end
      return i, source[i]
    end
  end
  error('Seq: expected function or table, got ' .. type(source), 3)
end

Seq = class 'Seq' {
  __init = function(self, source)
    rawset(self, '_iter', to_iterator(source))
  end,

  -- -------------------------------------------------------------
  -- Lazy transformations
  -- -------------------------------------------------------------

  --- Maps a function over each element.
  -- @param fn function(value) -> new_value
  -- @return new Seq
  map = function(self, fn)
    local source = self._iter
    local i = 0
    return Seq(function()
      local ctrl, v = source()
      if ctrl == nil then return nil end
      i = i + 1
      return i, fn(v)
    end)
  end,

  --- Keeps elements for which predicate(value) is truthy.
  -- @param predicate function(value) -> boolean
  -- @return new Seq
  filter = function(self, predicate)
    local source = self._iter
    local i = 0
    return Seq(function()
      while true do
        local ctrl, v = source()
        if ctrl == nil then return nil end
        if predicate(v) then
          i = i + 1
          return i, v
        end
      end
    end)
  end,

  --- Drops elements for which predicate(value) is truthy.
  reject = function(self, predicate)
    return self:filter(function(v) return not predicate(v) end)
  end,

  --- Yields the first n elements.
  take = function(self, n)
    local source = self._iter
    local count = 0
    return Seq(function()
      if count >= n then return nil end
      local ctrl, v = source()
      if ctrl == nil then return nil end
      count = count + 1
      return count, v
    end)
  end,

  --- Skips the first n elements, then yields the rest.
  drop = function(self, n)
    local source = self._iter
    local skipped = 0
    local i = 0
    return Seq(function()
      while skipped < n do
        if source() == nil then return nil end
        skipped = skipped + 1
      end
      local ctrl, v = source()
      if ctrl == nil then return nil end
      i = i + 1
      return i, v
    end)
  end,

  --- Yields elements while predicate(value) is truthy, then stops.
  take_while = function(self, predicate)
    local source = self._iter
    local done = false
    local i = 0
    return Seq(function()
      if done then return nil end
      local ctrl, v = source()
      if ctrl == nil then return nil end
      if not predicate(v) then
        done = true
        return nil
      end
      i = i + 1
      return i, v
    end)
  end,

  --- Drops elements while predicate(value) is truthy, then yields
  -- the rest unchanged.
  drop_while = function(self, predicate)
    local source = self._iter
    local dropped = false
    local i = 0
    return Seq(function()
      while not dropped do
        local ctrl, v = source()
        if ctrl == nil then return nil end
        if not predicate(v) then
          dropped = true
          i = i + 1
          return i, v
        end
      end
      local ctrl, v = source()
      if ctrl == nil then return nil end
      i = i + 1
      return i, v
    end)
  end,

  --- Maps each element to an iterable and flattens one level.
  -- @param fn function(value) -> iterable
  flat_map = function(self, fn)
    local source = self._iter
    local current = nil
    local i = 0
    return Seq(function()
      while true do
        if current then
          local ctrl, v = current()
          if ctrl ~= nil then
            i = i + 1
            return i, v
          end
          current = nil
        end
        local ctrl, v = source()
        if ctrl == nil then return nil end
        current = to_iterator(fn(v))
      end
    end)
  end,

  --- Removes duplicates by (optional) key function.
  -- @param key_fn function(value) -> any (default: identity)
  distinct = function(self, key_fn)
    key_fn = key_fn or function(v) return v end
    local source = self._iter
    local seen = {}
    local i = 0
    return Seq(function()
      while true do
        local ctrl, v = source()
        if ctrl == nil then return nil end
        local key = key_fn(v)
        if not seen[key] then
          seen[key] = true
          i = i + 1
          return i, v
        end
      end
    end)
  end,

  --- Wraps each element as a pair {index, value} starting at 1.
  -- Useful between map/filter steps to recover positional info.
  enumerate = function(self)
    local source = self._iter
    local i = 0
    return Seq(function()
      local ctrl, v = source()
      if ctrl == nil then return nil end
      i = i + 1
      return i, {i, v}
    end)
  end,

  --- Calls fn for side effects on each element, passing values through.
  -- @param fn function(value): any
  tap = function(self, fn)
    local source = self._iter
    return Seq(function()
      local ctrl, v = source()
      if ctrl == nil then return nil end
      fn(v)
      return ctrl, v
    end)
  end,

  -- -------------------------------------------------------------
  -- Terminators
  -- -------------------------------------------------------------

  --- Materializes the sequence into a List.
  collect = function(self)
    local List = require('llx.types.list').List
    local result = List{}
    for _, v in self._iter do
      result:insert(v)
    end
    return result
  end,

  --- Alias for collect.
  to_list = function(self)
    return self:collect()
  end,

  --- Calls fn for each element. Returns nothing.
  for_each = function(self, fn)
    for _, v in self._iter do
      fn(v)
    end
  end,

  --- Folds the sequence into a single value via fn.
  -- @param fn function(acc, value) -> new_acc
  -- @param init optional initial accumulator
  reduce = function(self, fn, init)
    local acc = init
    local first = init == nil
    for _, v in self._iter do
      if first then
        acc = v
        first = false
      else
        acc = fn(acc, v)
      end
    end
    if first then
      error('reduce of empty Seq with no initial value', 2)
    end
    return acc
  end,

  --- Returns the number of elements consumed.
  count = function(self)
    local n = 0
    for _ in self._iter do n = n + 1 end
    return n
  end,

  --- Returns the first element, or nil if empty.
  first = function(self)
    local _, v = self._iter()
    return v
  end,

  --- Returns the last element, or nil if empty.
  last = function(self)
    local result = nil
    for _, v in self._iter do result = v end
    return result
  end,

  --- True if any element satisfies predicate (default: truthy).
  any = function(self, predicate)
    predicate = predicate or function(v) return v end
    for _, v in self._iter do
      if predicate(v) then return true end
    end
    return false
  end,

  --- True if every element satisfies predicate.
  all = function(self, predicate)
    for _, v in self._iter do
      if not predicate(v) then return false end
    end
    return true
  end,

  --- True if no element satisfies predicate.
  none = function(self, predicate)
    for _, v in self._iter do
      if predicate(v) then return false end
    end
    return true
  end,

  --- Returns the first element matching predicate, or nil.
  find = function(self, predicate)
    for _, v in self._iter do
      if predicate(v) then return v end
    end
    return nil
  end,

  --- Sum of all elements. Assumes numeric.
  sum = function(self)
    local total = 0
    for _, v in self._iter do total = total + v end
    return total
  end,

  --- Product of all elements. Assumes numeric.
  product = function(self)
    local total = 1
    for _, v in self._iter do total = total * v end
    return total
  end,

  --- Minimum element. Returns nil for empty.
  min = function(self)
    local best = nil
    for _, v in self._iter do
      if best == nil or v < best then best = v end
    end
    return best
  end,

  --- Maximum element. Returns nil for empty.
  max = function(self)
    local best = nil
    for _, v in self._iter do
      if best == nil or v > best then best = v end
    end
    return best
  end,

  -- -------------------------------------------------------------
  -- Iteration protocol: a Seq is itself a Lua iterator.
  -- -------------------------------------------------------------

  __call = function(self, state, control)
    return self._iter(state, control)
  end,
}

return _M

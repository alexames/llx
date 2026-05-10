-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Double-ended queue with O(1) push/pop on both ends.
-- Backed by a sparse table indexed by first..last (inclusive).
-- @module llx.collections.deque

local class = require 'llx.class' . class
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

Deque = class 'Deque' {
  __init = function(self, iterable)
    rawset(self, '_storage', {})
    rawset(self, '_first', 1)
    rawset(self, '_last', 0)
    if iterable then
      if type(iterable) == 'function' then
        for _, v in iterable do
          self:push_right(v)
        end
      else
        for i = 1, #iterable do
          self:push_right(iterable[i])
        end
      end
    end
  end,

  push_right = function(self, value)
    self._last = self._last + 1
    self._storage[self._last] = value
    return self
  end,

  push_left = function(self, value)
    self._first = self._first - 1
    self._storage[self._first] = value
    return self
  end,

  -- Alias matching Python collections.deque conventions.
  push = function(self, value)
    return self:push_right(value)
  end,

  pop_right = function(self)
    if self._last < self._first then
      error('pop_right from empty Deque', 2)
    end
    local v = self._storage[self._last]
    self._storage[self._last] = nil
    self._last = self._last - 1
    return v
  end,

  pop_left = function(self)
    if self._last < self._first then
      error('pop_left from empty Deque', 2)
    end
    local v = self._storage[self._first]
    self._storage[self._first] = nil
    self._first = self._first + 1
    return v
  end,

  pop = function(self)
    return self:pop_right()
  end,

  peek_right = function(self)
    if self._last < self._first then return nil end
    return self._storage[self._last]
  end,

  peek_left = function(self)
    if self._last < self._first then return nil end
    return self._storage[self._first]
  end,

  is_empty = function(self)
    return self._last < self._first
  end,

  clear = function(self)
    self._storage = {}
    self._first = 1
    self._last = 0
    return self
  end,

  contains = function(self, value)
    for i = self._first, self._last do
      if self._storage[i] == value then return true end
    end
    return false
  end,

  -- Returns the value at logical position index (1-based, supports
  -- negative indices). Raises on out-of-range.
  at = function(self, index)
    local len = self._last - self._first + 1
    if index < 0 then index = len + index + 1 end
    if index < 1 or index > len then
      error('Deque index ' .. tostring(index) .. ' out of range', 2)
    end
    return self._storage[self._first + index - 1]
  end,

  __len = function(self)
    return self._last - self._first + 1
  end,

  __eq = function(self, other)
    if #self ~= #other then return false end
    for i = 0, #self - 1 do
      if self._storage[self._first + i]
          ~= other._storage[other._first + i] then
        return false
      end
    end
    return true
  end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    for i = 0, #self - 1 do
      result = hash.hash_value(i + 1, result)
      result = hash.hash_value(self._storage[self._first + i], result)
    end
    return result
  end,

  __tostring = function(self)
    local parts = {}
    for i = 0, #self - 1 do
      parts[i + 1] = tostring(self._storage[self._first + i])
    end
    return 'Deque{' .. table.concat(parts, ', ') .. '}'
  end,

  __call = function(self, state, control)
    control = (control or 0) + 1
    if control > #self then return nil end
    return control, self._storage[self._first + control - 1]
  end,
}

return _M

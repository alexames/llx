-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Map that preserves insertion order through deletes.
-- Lua tables only preserve insertion order until a key is deleted;
-- OrderedDict guarantees iteration order matches insertion order
-- regardless of intervening deletes.
--
-- Backed by a doubly-linked list of {key, value} nodes plus a
-- hash from key to node, so set/get/delete are O(1) and iteration
-- is O(n) in linked-list order.
-- @module llx.collections.ordered_dict

local class = require 'llx.class' . class
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

OrderedDict = class 'OrderedDict' {
  __init = function(self, source)
    rawset(self, '_index', {})
    rawset(self, '_first', nil)
    rawset(self, '_last', nil)
    rawset(self, '_size', 0)
    if source == nil then return end
    if type(source) == 'function' then
      for k, v in source do
        self:set(k, v)
      end
    elseif type(source) == 'table' then
      -- Expect a sequence of {key, value} pairs. Map-form input
      -- is deliberately not supported because Lua's pairs() order
      -- over a literal map is implementation-defined and would
      -- defeat the point of an order-preserving container.
      for i = 1, #source do
        local pair = source[i]
        self:set(pair[1], pair[2])
      end
    end
  end,

  set = function(self, key, value)
    local node = self._index[key]
    if node then
      node.value = value
      return self
    end
    node = {key = key, value = value, prev = self._last, next_ = nil}
    if self._last then
      self._last.next_ = node
    else
      self._first = node
    end
    self._last = node
    self._index[key] = node
    self._size = self._size + 1
    return self
  end,

  get = function(self, key)
    local node = self._index[key]
    if node then return node.value end
    return nil
  end,

  delete = function(self, key)
    local node = self._index[key]
    if node == nil then return false end
    if node.prev then
      node.prev.next_ = node.next_
    else
      self._first = node.next_
    end
    if node.next_ then
      node.next_.prev = node.prev
    else
      self._last = node.prev
    end
    self._index[key] = nil
    self._size = self._size - 1
    return true
  end,

  contains = function(self, key)
    return self._index[key] ~= nil
  end,

  keys = function(self)
    local result = {}
    local node = self._first
    while node do
      result[#result + 1] = node.key
      node = node.next_
    end
    return result
  end,

  values = function(self)
    local result = {}
    local node = self._first
    while node do
      result[#result + 1] = node.value
      node = node.next_
    end
    return result
  end,

  -- Returns a list of {key, value} pairs in insertion order.
  items = function(self)
    local result = {}
    local node = self._first
    while node do
      result[#result + 1] = {node.key, node.value}
      node = node.next_
    end
    return result
  end,

  clear = function(self)
    self._index = {}
    self._first = nil
    self._last = nil
    self._size = 0
    return self
  end,

  -- Move an existing key to the end of the order. No-op if
  -- the key isn't present.
  move_to_end = function(self, key)
    local node = self._index[key]
    if node == nil or node == self._last then return self end
    if node.prev then
      node.prev.next_ = node.next_
    else
      self._first = node.next_
    end
    node.next_.prev = node.prev
    node.prev = self._last
    node.next_ = nil
    self._last.next_ = node
    self._last = node
    return self
  end,

  __len = function(self) return self._size end,

  __pairs = function(self)
    local node = self._first
    return function()
      if node == nil then return nil end
      local k, v = node.key, node.value
      node = node.next_
      return k, v
    end
  end,

  -- Order-sensitive equality: same key sequence with same values.
  __eq = function(self, other)
    if self._size ~= other._size then return false end
    local n1 = self._first
    local n2 = other._first
    while n1 do
      if n1.key ~= n2.key or n1.value ~= n2.value then return false end
      n1 = n1.next_
      n2 = n2.next_
    end
    return true
  end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    local node = self._first
    while node do
      result = hash.hash_value(node.key, result)
      result = hash.hash_value(node.value, result)
      node = node.next_
    end
    return result
  end,

  __tostring = function(self)
    local parts = {}
    local node = self._first
    while node do
      parts[#parts + 1] =
        tostring(node.key) .. '=' .. tostring(node.value)
      node = node.next_
    end
    return 'OrderedDict{' .. table.concat(parts, ', ') .. '}'
  end,
}

return _M

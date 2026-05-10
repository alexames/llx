-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Binary heap (priority queue).
-- Min-heap by default. Constructor accepts an optional `less`
-- comparator to invert or customize ordering, and an optional
-- list of initial items to heapify in place. push and pop are
-- O(log n); peek is O(1).
-- @module llx.collections.heap

local class = require 'llx.class' . class
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local function default_less(a, b)
  return a < b
end

Heap = class 'Heap' {
  -- Heap()              -- empty min-heap
  -- Heap{less=fn}       -- empty with custom comparator
  -- Heap{1, 5, 3}       -- min-heap heapified from items
  -- Heap{1, 5, 3, less=fn} -- heapified with custom comparator
  __init = function(self, opts)
    opts = opts or {}
    rawset(self, '_data', {})
    rawset(self, '_less', opts.less or default_less)
    local data = self._data
    for i = 1, #opts do
      data[i] = opts[i]
    end
    -- Heapify: sift down from the last non-leaf to the root.
    for i = #data // 2, 1, -1 do
      self:_sift_down(i)
    end
  end,

  _sift_up = function(self, index)
    local data = self._data
    local less = self._less
    while index > 1 do
      local parent = index // 2
      if less(data[index], data[parent]) then
        data[index], data[parent] = data[parent], data[index]
        index = parent
      else
        break
      end
    end
  end,

  _sift_down = function(self, index)
    local data = self._data
    local less = self._less
    local n = #data
    while true do
      local left = 2 * index
      local right = left + 1
      local smallest = index
      if left <= n and less(data[left], data[smallest]) then
        smallest = left
      end
      if right <= n and less(data[right], data[smallest]) then
        smallest = right
      end
      if smallest == index then break end
      data[index], data[smallest] = data[smallest], data[index]
      index = smallest
    end
  end,

  push = function(self, value)
    local data = self._data
    data[#data + 1] = value
    self:_sift_up(#data)
    return self
  end,

  pop = function(self)
    local data = self._data
    local n = #data
    if n == 0 then
      error('pop from empty Heap', 2)
    end
    local top = data[1]
    if n == 1 then
      data[1] = nil
      return top
    end
    data[1] = data[n]
    data[n] = nil
    self:_sift_down(1)
    return top
  end,

  peek = function(self)
    return self._data[1]
  end,

  is_empty = function(self)
    return #self._data == 0
  end,

  clear = function(self)
    self._data = {}
    return self
  end,

  -- Returns up to n top items in priority order without mutating
  -- the heap. O(n + k log n) via repeated pop on a copy.
  top_n = function(self, n)
    local copy = Heap{less = self._less}
    for i = 1, #self._data do
      copy._data[i] = self._data[i]
    end
    local result = {}
    for _ = 1, math.min(n, #copy._data) do
      result[#result + 1] = copy:pop()
    end
    return result
  end,

  __len = function(self)
    return #self._data
  end,

  __tostring = function(self)
    local parts = {}
    for i = 1, #self._data do
      parts[i] = tostring(self._data[i])
    end
    return 'Heap{' .. table.concat(parts, ', ') .. '}'
  end,

  -- Equality compares the heap as a multiset under the same
  -- ordering: pop-and-compare on copies. Two heaps with the same
  -- elements but different internal arrays still compare equal.
  __eq = function(self, other)
    if #self._data ~= #other._data then return false end
    if self._less ~= other._less then return false end
    local a = Heap{less = self._less}
    local b = Heap{less = other._less}
    for i = 1, #self._data do a._data[i] = self._data[i] end
    for i = 1, #other._data do b._data[i] = other._data[i] end
    -- Re-heapify both copies (they share the underlying order).
    for i = #a._data // 2, 1, -1 do a:_sift_down(i) end
    for i = #b._data // 2, 1, -1 do b:_sift_down(i) end
    while #a._data > 0 do
      if a:pop() ~= b:pop() then return false end
    end
    return true
  end,
}

--- Returns the n largest items from a sequence using a heap.
-- @param sequence A sequence-shaped table.
-- @param n Number of items to return.
-- @return A list of up to n items in descending order.
function nlargest(sequence, n)
  if n <= 0 then return {} end
  -- Maintain a min-heap of size n; the root is the smallest of
  -- the largest n seen so far.
  local heap = Heap{}
  for i = 1, #sequence do
    local v = sequence[i]
    if #heap < n then
      heap:push(v)
    elseif v > heap:peek() then
      heap:pop()
      heap:push(v)
    end
  end
  -- Drain into a list in descending order.
  local result = {}
  while #heap > 0 do
    result[#heap] = heap:pop()
  end
  return result
end

--- Returns the n smallest items from a sequence using a heap.
-- @param sequence A sequence-shaped table.
-- @param n Number of items to return.
-- @return A list of up to n items in ascending order.
function nsmallest(sequence, n)
  if n <= 0 then return {} end
  local heap = Heap{less = function(a, b) return a > b end}
  for i = 1, #sequence do
    local v = sequence[i]
    if #heap < n then
      heap:push(v)
    elseif v < heap:peek() then
      heap:pop()
      heap:push(v)
    end
  end
  local result = {}
  while #heap > 0 do
    result[#heap] = heap:pop()
  end
  return result
end

return _M

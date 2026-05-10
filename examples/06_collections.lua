-- examples/06_collections.lua
-- New collection types: Deque, Counter, OrderedDict, DefaultDict, Heap.

local llx = require 'llx'

-- Deque: O(1) push/pop on both ends.
local Deque = llx.Deque
local q = Deque{1, 2, 3}
q:push_left(0)
q:push_right(4)
print(tostring(q))             --> Deque{0, 1, 2, 3, 4}
print(q:pop_left(), q:pop_right())  --> 0, 4

-- Counter: frequency map.
local Counter = llx.Counter
local words = {'apple', 'banana', 'apple', 'cherry', 'apple', 'banana'}
local counts = Counter(words)
print(counts:get('apple'))     --> 3
print(counts:total())          --> 6
for _, pair in ipairs(counts:most_common(2)) do
  print(pair[1], pair[2])      --> apple 3, banana 2
end

-- Counter arithmetic: merge or subtract two counters.
local diff = Counter{a = 5, b = 1} - Counter{a = 3, b = 5}
print(diff:get('a'))           --> 2
print(diff:get('b'))           --> 0 (clamped from -4)

-- OrderedDict: preserves insertion order through deletes.
local OrderedDict = llx.OrderedDict
local od = OrderedDict{{'first', 1}, {'second', 2}, {'third', 3}}
od:delete('second')
od:set('fourth', 4)
for k, v in pairs(od) do
  print(k, v)                  --> first 1, third 3, fourth 4
end

-- DefaultDict: factory-backed lookups for the table-of-X pattern.
local DefaultDict = llx.DefaultDict
local groups = DefaultDict(function() return llx.List{} end)
for _, n in ipairs({1, 2, 3, 4, 5, 6, 7, 8}) do
  local key = (n % 2 == 0) and 'even' or 'odd'
  groups:get(key):insert(n)
end
print('evens:', tostring(groups:get('even')))  --> List{2, 4, 6, 8}
print('odds: ', tostring(groups:get('odd')))   --> List{1, 3, 5, 7}

-- Heap: priority queue with O(log n) push/pop.
local Heap = llx.Heap
local h = Heap{5, 1, 4, 2, 3}
print(h:peek())                --> 1 (min-heap)
while not h:is_empty() do
  io.write(h:pop(), ' ')       --> 1 2 3 4 5
end
io.write('\n')

-- nlargest / nsmallest helpers using a bounded heap.
local heap_module = require 'llx.collections.heap'
print('top 3:', table.concat(heap_module.nlargest(
  {3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5}, 3), ', '))  --> 9, 6, 5
print('bot 3:', table.concat(heap_module.nsmallest(
  {3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5}, 3), ', '))  --> 1, 1, 2

-- benchmarks/bench_collections.lua
-- New collection types compared with naive table-based equivalents.

local llx = require 'llx'
local Deque = llx.Deque
local Counter = llx.Counter
local OrderedDict = llx.OrderedDict
local Heap = llx.Heap

return {
  -- Deque: O(1) on both ends. Compare against table.remove(t, 1)
  -- (O(n) shift) for the queue use-case.
  ['Deque push_right + pop_left, 100k'] = function()
    local d = Deque()
    for i = 1, 100000 do d:push_right(i) end
    for _ = 1, 100000 do d:pop_left() end
  end,

  ['table-as-queue push + table.remove(t, 1), 10k'] = function()
    -- 10x smaller because table.remove(t, 1) is O(n).
    local t = {}
    for i = 1, 10000 do t[#t + 1] = i end
    while #t > 0 do table.remove(t, 1) end
  end,

  -- Counter: frequency map.
  ['Counter from 100k string sequence'] = function()
    local words = {}
    for i = 1, 100000 do
      words[i] = 'word_' .. (i % 1000)
    end
    Counter(words)
  end,

  ['Counter most_common(10) over 1k keys'] = function()
    local c = Counter()
    for i = 1, 1000 do c:set('k' .. i, math.random(1000)) end
    for _ = 1, 1000 do c:most_common(10) end
  end,

  -- OrderedDict: linked-list ops.
  ['OrderedDict 10k set + 10k delete'] = function()
    local od = OrderedDict()
    for i = 1, 10000 do od:set('k' .. i, i) end
    for i = 1, 10000 do od:delete('k' .. i) end
  end,

  ['OrderedDict iterate 10k entries'] = function()
    local od = OrderedDict()
    for i = 1, 10000 do od:set('k' .. i, i) end
    for _ = 1, 10 do
      for _, _ in pairs(od) do end
    end
  end,

  -- Heap: priority queue.
  ['Heap push 10k random, pop all'] = function()
    math.randomseed(42)
    local h = Heap()
    for _ = 1, 10000 do h:push(math.random(100000)) end
    while not h:is_empty() do h:pop() end
  end,

  ['Heap heapify 10k items'] = function()
    local items = {}
    math.randomseed(42)
    for i = 1, 10000 do items[i] = math.random(100000) end
    local _ = Heap(items)
  end,
}

-- benchmarks/bench_hash.lua
-- FNV-1a value hashing across primitive and composite types.

local llx = require 'llx'
local hash = llx.hash.hash
local Tuple = require 'llx.tuple'.Tuple
local List = llx.List

return {
  ['hash 100k integers'] = function()
    for i = 1, 100000 do hash(i) end
  end,

  ['hash 100k floats'] = function()
    for i = 1, 100000 do hash(i + 0.5) end
  end,

  ['hash 100k short strings'] = function()
    for i = 1, 100000 do hash('item_' .. i) end
  end,

  ['hash 10k tuples (size 4)'] = function()
    for i = 1, 10000 do
      hash(Tuple{i, i + 1, i + 2, i + 3})
    end
  end,

  ['hash 10k lists (size 10)'] = function()
    local list = List{}
    for i = 1, 10 do list:insert(i) end
    for _ = 1, 10000 do hash(list) end
  end,

  ['hash 10k plain tables (10 keys)'] = function()
    for i = 1, 10000 do
      hash({a = i, b = i + 1, c = i + 2, d = i + 3, e = i + 4,
            f = i + 5, g = i + 6, h = i + 7, i = i + 8, j = i + 9})
    end
  end,
}

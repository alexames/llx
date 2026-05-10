-- benchmarks/bench_hash_table.lua
-- HashTable: value-equality lookups by hashed keys.

local llx = require 'llx'
local HashTable = require 'llx.hash_table'.HashTable
local Tuple = require 'llx.tuple'.Tuple

return {
  ['HashTable insert 10k tuple keys'] = function()
    local ht = HashTable()
    for i = 1, 10000 do
      ht[Tuple{i, i + 1}] = i
    end
  end,

  ['HashTable lookup 10k tuple keys (hit)'] = function()
    local ht = HashTable()
    local keys = {}
    for i = 1, 10000 do
      keys[i] = Tuple{i, i + 1}
      ht[keys[i]] = i
    end
    for i = 1, 10000 do
      local _ = ht[keys[i]]
    end
  end,

  ['HashTable lookup 10k tuple keys (miss)'] = function()
    local ht = HashTable()
    for i = 1, 10000 do ht[Tuple{i, i + 1}] = i end
    for i = 1, 10000 do
      local _ = ht[Tuple{i + 1000000, 0}]
    end
  end,

  ['HashTable insert 10k string keys'] = function()
    local ht = HashTable()
    for i = 1, 10000 do
      ht['key_' .. i] = i
    end
  end,
}

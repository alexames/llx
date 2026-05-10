-- benchmarks/bench_list.lua
-- List operations: indexing, slicing, methods.

local llx = require 'llx'
local List = llx.List

local function build(n)
  local list = List{}
  for i = 1, n do list:insert(i) end
  return list
end

return {
  ['List build 100k via :insert'] = function()
    local list = List{}
    for i = 1, 100000 do list:insert(i) end
  end,

  ['List index 1M numeric reads'] = function()
    local list = build(1000)
    local sum = 0
    for _ = 1, 1000 do
      for i = 1, 1000 do sum = sum + list[i] end
    end
  end,

  ['List negative-index 100k reads'] = function()
    local list = build(1000)
    for _ = 1, 100 do
      for i = 1, 1000 do
        local _ = list[-i]
      end
    end
  end,

  ['List :map over 10k elements'] = function()
    local list = build(10000)
    list:map(function(v) return v * 2 end)
  end,

  ['List :filter over 10k elements'] = function()
    local list = build(10000)
    list:filter(function(v) return v % 2 == 0 end)
  end,

  ['List :reduce over 10k elements'] = function()
    local list = build(10000)
    list:reduce(function(acc, v) return acc + v end, 0)
  end,

  ['List concat (a .. b), 1k * 1k'] = function()
    local a = build(1000)
    local b = build(1000)
    for _ = 1, 100 do local _ = a .. b end
  end,
}

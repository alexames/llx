-- benchmarks/bench_functional.lua
-- llx.functional: iterators, transforms, reductions.

local llx = require 'llx'
local f = llx.functional

return {
  ['range(1, 100k) iteration'] = function()
    local sum = 0
    for _, v in f.range(1, 100000) do sum = sum + v end
  end,

  ['map(double, range(100k)) collect'] = function()
    f.map(function(x) return x * 2 end, f.range(1, 100000))
  end,

  ['filter even, range(100k)'] = function()
    for _, v in f.filter(function(x) return x % 2 == 0 end,
                         f.range(1, 100000)) do
      local _ = v
    end
  end,

  ['reduce sum over range(100k)'] = function()
    f.reduce(f.range(1, 100000), function(a, b) return a + b end, 0)
  end,

  ['enumerate range(10k) x10'] = function()
    for _ = 1, 10 do
      for _, _, _ in f.enumerate(f.range(1, 10000)) do end
    end
  end,

  ['zip two range(10k) iters x10'] = function()
    for _ = 1, 10 do
      for _, _, _ in f.zip(f.range(1, 10000), f.range(1, 10000)) do end
    end
  end,

  ['memoize fib(30) x100'] = function()
    local fib
    fib = f.memoize(function(n)
      if n <= 1 then return n end
      return fib(n - 1) + fib(n - 2)
    end)
    for _ = 1, 100 do fib(30) end
  end,
}

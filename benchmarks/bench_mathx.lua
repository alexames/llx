-- benchmarks/bench_mathx.lua
-- Statistical and numeric utilities.

local llx = require 'llx'
local mathx = llx.mathx

local function gen_seq(n)
  math.randomseed(42)
  local t = {}
  for i = 1, n do t[i] = math.random() * 1000 end
  return t
end

return {
  ['mathx.mean over 100k floats'] = function()
    local seq = gen_seq(100000)
    mathx.mean(seq)
  end,

  ['mathx.median over 10k floats'] = function()
    local seq = gen_seq(10000)
    for _ = 1, 100 do mathx.median(seq) end
  end,

  ['mathx.variance over 10k floats'] = function()
    local seq = gen_seq(10000)
    for _ = 1, 100 do mathx.variance(seq) end
  end,

  ['mathx.quantile over 10k floats x100'] = function()
    local seq = gen_seq(10000)
    for _ = 1, 100 do mathx.quantile(seq, 0.5) end
  end,

  ['mathx.gcd 1M iterations'] = function()
    for i = 1, 1000000 do mathx.gcd(i, i + 7) end
  end,

  ['mathx.harmonic_mean over 10k positives'] = function()
    local seq = gen_seq(10000)
    for _ = 1, 100 do mathx.harmonic_mean(seq) end
  end,
}

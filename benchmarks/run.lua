-- benchmarks/run.lua
-- Discover and run all benchmark files, printing a one-line
-- summary per benchmark with elapsed time. Each bench_*.lua file
-- returns a table mapping benchmark name -> zero-arg function.

local files = {
  'bench_hash',
  'bench_list',
  'bench_hash_table',
  'bench_collections',
  'bench_mathx',
  'bench_functional',
}

-- ANSI helpers, falling back to plain text if not a TTY.
local IS_TTY = io.stderr:seek() == nil
local function fmt(s, color)
  if not IS_TTY then return s end
  local codes = {green = 32, yellow = 33, red = 31, dim = 2}
  return string.format('\27[%dm%s\27[0m', codes[color] or 0, s)
end

local function bench_one(name, fn)
  -- Warm up the JIT/cache for one short run, then time the real one.
  local pcall_ok = pcall(fn)
  if not pcall_ok then
    return nil, 'errored'
  end
  local start = os.clock()
  fn()
  return os.clock() - start, nil
end

local function color_for(seconds)
  if seconds < 0.05 then return 'green' end
  if seconds < 0.5 then return 'yellow' end
  return 'red'
end

print(string.format('%-50s %12s', 'Benchmark', 'Time'))
print(string.rep('-', 65))

local total = 0
local count = 0
for _, file in ipairs(files) do
  local ok, benches = pcall(require, 'benchmarks.' .. file)
  if not ok then
    print(string.format('%-50s %12s', file, fmt('LOAD ERROR', 'red')))
    print('  ' .. fmt(tostring(benches), 'dim'))
  else
    -- Sort names for deterministic output.
    local names = {}
    for k in pairs(benches) do names[#names + 1] = k end
    table.sort(names)
    for _, name in ipairs(names) do
      local elapsed, err = bench_one(name, benches[name])
      if err then
        print(string.format('%-50s %12s', name, fmt('ERROR', 'red')))
      else
        local time_str = string.format('%.4fs', elapsed)
        print(string.format('%-50s %12s',
          name, fmt(time_str, color_for(elapsed))))
        total = total + elapsed
        count = count + 1
      end
    end
  end
end

print(string.rep('-', 65))
print(string.format('%-50s %12.4fs',
  string.format('Total (%d benchmarks)', count), total))

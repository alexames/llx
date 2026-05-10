# llx Benchmarks

A simple harness for tracking the cost of llx primitives over time.
Not a load test, not a comparison against other libraries — just
"is this still fast?" for the hot paths.

## Running

After installing llx with `luarocks make --local`:

```sh
eval "$(luarocks-5.4 path)"
lua5.4 benchmarks/run.lua
```

If your `lua` binary is already 5.4 and luarocks is on the default
path, the eval is unnecessary.

## What's measured

Each `bench_*.lua` file returns a table mapping a benchmark name to
a zero-argument function. The harness runs each function once
(after a warm-up call) and reports the elapsed `os.clock()` time.

| File                    | Covers                                        |
|-------------------------|-----------------------------------------------|
| `bench_hash.lua`        | FNV-1a hashing across primitives, tuples, lists, plain tables |
| `bench_list.lua`        | List build, indexing, slicing, methods         |
| `bench_hash_table.lua`  | HashTable insert and lookup with tuple/string keys |
| `bench_collections.lua` | Deque vs table-as-queue, Counter, OrderedDict, Heap |
| `bench_mathx.lua`       | mean, median, variance, quantile, gcd, harmonic_mean |
| `bench_functional.lua`  | range, map, filter, reduce, enumerate, zip, memoize |

## Adding benchmarks

Drop a new `bench_<area>.lua` file in this directory that returns a
table of name -> function, and add the file's basename to the
`files` table in `run.lua`. Each function should perform enough
work to take 0.001s-1s on a modern machine; very-fast benches lose
signal to clock granularity.

## Caveats

- `os.clock()` measures CPU time; wall time would differ when the
  process is interrupted.
- No statistical sampling, no warmup beyond a single pcall.
- Numbers are not comparable across machines or across Lua versions.
- For tracking regressions, run on the same machine with a clean
  load and compare relative columns, not absolute times.

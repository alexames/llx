# llx — Lua Extension Library

A comprehensive utility library for Lua 5.4+. Brings object-oriented
programming, functional programming, runtime type checking, schema
validation, structured exceptions, sum types, ergonomic collections,
path manipulation, pretty-printing, context managers, unit testing,
and a bytecode reader to Lua development.

Zero external runtime dependencies. Just Lua 5.4.

## Installation

Via LuaRocks using the custom server:

```sh
luarocks install llx --server=https://alexames.github.io/luarocks-repository
```

Or clone the repository directly:

```sh
git clone https://github.com/alexames/llx.git
```

## Quick start

```lua
local llx = require 'llx'

-- Classes with inheritance, properties, and conversions
local Animal = llx.class 'Animal' {
  __init = function(self, name) self.name = name end,
  speak = function(self) return self.name .. ' makes a sound' end,
}

local Dog = llx.class 'Dog' : extends(Animal) {
  speak = function(self) return self.name .. ' says woof' end,
}

-- Collections that hash and compare by value
local seen = llx.Set{}
seen:insert(Dog('Rex'))

-- Sum types instead of nil-or-throw
local function parse_age(s)
  local n = tonumber(s)
  if n == nil then return llx.Err('not a number') end
  return llx.Ok(n)
end

-- Schema validation
local PersonSchema = llx.Schema {
  type = llx.Table,
  properties = {
    name = llx.Schema{type = llx.String, min_length = 1},
    age = llx.Schema{type = llx.Integer, minimum = 0},
  },
  required = {'name', 'age'},
}
llx.matches_schema(PersonSchema, {name = 'Alice', age = 30})
```

## Capabilities

### Classes

`class 'Name' { ... }` defines a class with optional inheritance,
properties, metamethods, and auto-generated conversion functions.

```lua
local Rectangle = llx.class 'Rectangle' {
  __init = function(self, w, h)
    self._w, self._h = w, h
  end,
  ['width' | llx.property] = {
    get = function(self) return self._w end,
    set = function(self, v) self._w = v end,
  },
  ['area' | llx.property] = {
    get = function(self) return self._w * self._h end,  -- read-only
  },
}

local r = Rectangle(10, 5)
print(r.area)     --> 50
r.width = 7
print(r.area)     --> 35
```

Metamethods, multiple inheritance, named-superclass references
(`self.Base.__init(self, ...)`), and per-class `to_Name(value)`
conversion functions are all supported.

### Collections

Value-comparing, value-hashing collections in a unified style.

| Type           | Use case                                             |
|----------------|------------------------------------------------------|
| `List`         | Sequence with map/filter/reduce/slice methods        |
| `Set`          | Unordered unique values; `|`, `&`, `-`, `~` operators|
| `Tuple`        | Immutable, lexicographically-ordered, hashable       |
| `Counter`      | Frequency map with `+` / `-` arithmetic              |
| `Deque`        | O(1) push/pop on both ends                           |
| `OrderedDict`  | Map that preserves insertion order through deletes   |
| `DefaultDict`  | Factory-backed lookups (`groups:get('x'):insert(v)`) |
| `Heap`         | Binary heap / priority queue with custom comparator  |
| `HashTable`    | Map keyed by value-equality, hashes any `__hash`-able|
| `namedtuple`   | Positional immutable record (Python-like)            |
| `dataclass`    | Named-field record with defaults, mutable or frozen  |

```lua
local Point = llx.namedtuple('Point', {'x', 'y'})
local Config = llx.dataclass('Config', {
  {name = 'host', type = llx.String},
  {name = 'port', type = llx.Integer, default = 80},
}, {immutable = true})

local counter = llx.Counter{'a', 'b', 'a', 'c', 'a'}
print(counter:most_common(2)[1][1])  --> 'a'

local heap = llx.Heap{5, 1, 4, 2, 3}
heap:pop()  --> 1 (min-heap)
```

### Sum types: Result and Option

Non-exceptional error handling without `pcall`-and-branch.

```lua
local function divide(a, b)
  if b == 0 then return llx.Err('division by zero') end
  return llx.Ok(a / b)
end

local result = divide(10, 2)
  :map(function(x) return x + 1 end)
  :and_then(function(x) return divide(x, 3) end)
  :unwrap_or(-1)

-- Option for absence rather than failure
local user = llx.Option.from_nilable(find_user(id))
local name = user:map(function(u) return u.name end):unwrap_or('(unknown)')

-- Convert pcall results to Result
local parsed = llx.Result.try(json_decode, raw_string)
```

### Functional programming + chainable Seq

Iterator-based utilities inspired by Python's `itertools` and
`functools`. Plus a `Seq` class for top-to-bottom method chaining.

```lua
local f = llx.functional

-- itertools-style: lazy by default
for _, n in f.range(1, 100) do ... end
for _, batch in f.batched(f.range(1, 100), 10) do ... end

-- Reductions
local total = f.sum(f.range(1, 101))
local groups = f.group_by({1,2,3,4,5}, function(v) return v % 2 end)

-- Combinators
local add5 = f.partial(function(a, b) return a + b end, 5)
local pipeline = f.pipe(double, add5, tostring)

-- Seq for chainable pipelines
local result = llx.Seq({1, 2, 3, 4, 5})
  :map(function(x) return x * x end)
  :filter(function(x) return x > 4 end)
  :collect()
-- List{9, 16, 25}
```

### Runtime type checking and schema validation

Type checkers, isinstance, and schemas with constraints, default
values, nested validation, and structural types.

```lua
-- Built-in type singletons
llx.isinstance(42, llx.Integer)      --> true
llx.isinstance(3.14, llx.Float)      --> true
llx.isinstance({}, llx.Table)        --> true

-- Composite matchers
local matchers = require 'llx.types.matchers'
local NumberOrString = matchers.Union{llx.Number, llx.String}
local OptionalName = matchers.Optional(llx.String)
local NameAges = matchers.Dict(llx.String, llx.Integer)
local UserShape = matchers.Protocol{
  name = llx.String,
  age = llx.Integer,
}

-- Schema with constraints
local Schema = llx.Schema
local AgeSchema = Schema{
  type = llx.Integer,
  minimum = 0,
  maximum = 150,
}
local NameSchema = Schema{
  type = llx.String,
  min_length = 1,
  max_length = 100,
  pattern = '^%a',  -- starts with a letter
}
local StatusSchema = Schema{
  type = llx.String,
  one_of = {'active', 'pending', 'closed'},
}

-- Per-type constraints (already implemented for Number / String / Table)
-- plus generic one_of and predicate.
local EvenInt = Schema{
  type = llx.Integer,
  predicate = function(n) return n % 2 == 0 end,
}
```

### Structured exceptions

A real exception hierarchy with inheritance and a `try / catch`
flow-control DSL. Exceptions carry a captured traceback at construction
time; `:message()` returns the short form, `tostring()` the full one.

```lua
local exceptions = llx.exceptions

local try, catch = llx.flow_control.try, llx.flow_control.catch

try {
  function()
    if input == nil then
      error(exceptions.ValueException('input required'))
    end
  end;
  catch(exceptions.ValueException, function(e)
    log(e:message())  -- short form: "ValueException: input required"
  end);
  catch(exceptions.Exception, function(e)
    log(tostring(e))  -- full form: includes traceback
  end);
}
```

Built-in classes: `Exception`, `ExceptionGroup`, `IndexError`,
`InvalidArgumentException`, `InvalidArgumentTypeException`,
`NotImplementedException`, `RuntimeError`, `SchemaException` (+
field-mismatch, constraint-failure, missing-field variants),
`TypeError`, `ValueException`. Define your own by extending `Exception`.

### Path manipulation

POSIX-style path manipulation plus minimal filesystem helpers using
only Lua's stdlib (no `lfs` dependency).

```lua
local Path = llx.path.Path

local p = Path('/etc/config.json')
p:parent():name()              --> 'etc'
p:stem()                       --> 'config'
p:suffix()                     --> '.json'
p:with_suffix('.yaml')         --> Path('/etc/config.yaml')

-- /-operator for joining
local config_path = Path('/etc') / 'app' / 'settings.json'

-- Filesystem helpers (stdlib only)
if p:exists() then
  local content = p:read_text()
  Path('/tmp/copy.json'):write_text(content)
end
```

Free functions for one-liners: `path.join`, `path.split`,
`path.dirname`, `path.basename`, `path.splitext`, `path.normalize`,
`path.is_absolute`. Directory listing and stat (file vs dir, mtime,
permissions) need a filesystem library — see *Companion libraries*.

### Pretty-printing

```lua
print(llx.pretty.format({
  name = 'Alice',
  hobbies = {'reading', 'hiking'},
  addresses = {
    {city = 'NYC', zip = '10001'},
    {city = 'LA', zip = '90001'},
  },
}))
--> {
-->   addresses = {
-->     {city = "NYC", zip = "10001"},
-->     {city = "LA", zip = "90001"}
-->   },
-->   hobbies = {"reading", "hiking"},
-->   name = "Alice"
--> }
```

Cycle detection, deterministic key ordering, width-aware breaking
that accounts for key prefixes, and `__tostring` honor for classes.

### Context managers

```lua
local with = llx.contextlib.with

with(io.open('config.json', 'r'), function(file)
  return file:read('*a')
end)  -- file is closed whether the body returns or raises

-- Adapt :close-style values for use as Lua 5.4 <close>
local closing = llx.contextlib.closing
do
  local stream <close> = closing(some_stream)
  -- automatically cleaned up on scope exit
end
```

### Enums and Flag enums

```lua
local Color = llx.enum 'Color' {
  [1] = 'Red', [2] = 'Green', [3] = 'Blue',
}
print(Color.Red)         --> Color.Red
print(Color[1])          --> Color.Red

local Permission = require 'llx.enum'.Flag 'Permission' {
  Read = 1, Write = 2, Execute = 4,
}
local rw = Permission.Read | Permission.Write
rw:has(Permission.Read)        --> true
rw:has(Permission.Execute)     --> false
tostring(rw)                   --> 'Permission.Read|Write'
```

### Math, statistics, operators, bisect

```lua
local mathx = llx.mathx
mathx.clamp(15, 0, 10)                  --> 10
mathx.lerp(0, 100, 0.5)                 --> 50
mathx.mean({1, 2, 3, 4, 5})             --> 3
mathx.median({3, 1, 4, 1, 5, 9, 2, 6})  --> 3.5
mathx.variance({2, 4, 4, 4, 5, 5, 7, 9})
mathx.quantile({1, 2, 3, 4, 5}, 0.9)
mathx.gcd(12, 8)                        --> 4

-- Operators as first-class functions
local ops = llx.operators
local getter = ops.itemgetter('name')
local depth = ops.attrgetter('config.debug.level')

-- Binary search
local bisect = llx.bisect
local i = bisect.bisect_left({1, 3, 5, 7}, 4)   --> 3
bisect.insort_right(sorted_list, value)
```

### Unit testing

BDD-style framework with `describe`/`it`/`expect`, mocks and spies.

```lua
local unit = require 'llx.unit'
_ENV = unit.create_test_env(_ENV)

describe('parser', function()
  local p
  before_each(function() p = Parser() end)

  it('parses an integer', function()
    expect(p:parse('42')).to.be_equal_to(42)
  end)

  it('raises on garbage', function()
    expect(function() p:parse('xyz') end).to.throw()
  end)

  it('uses a mock for the logger', function()
    local log = Mock()
    p:set_logger(log)
    p:parse('1')
    expect(#log.calls).to.be_equal_to(1)
  end)
end)

if llx.main_file() then unit.run_unit_tests() end
```

### Strict mode

Catches accidental global variable creation at test time. Used
throughout llx itself.

```lua
local strict = require 'llx.strict'
local lock <close> = strict.lock_global_table()
-- typos in global names now error at use time
```

### Bytecode reader

Low-level inspection of compiled Lua bytecode for both Lua 5.4 and
Lua 5.5. Useful for tooling, decompilation, instrumentation.

```lua
local bc = require 'llx.bytecode'
local chunk = string.dump(my_function)
local proto = bc.lua54.bcode.read(chunk)
-- inspect proto.instructions, proto.constants, proto.protos, ...
```

### Module environment isolation

Every llx module uses `environment.create_module_environment()` to
isolate its top-level definitions from the global namespace. Available
to consumers too if you want strict module hygiene.

```lua
local _ENV, _M = require 'llx.environment'.create_module_environment()

-- Anything assigned without `local` ends up in _M, not in _G.
my_function = function() end
my_value = 42

return _M
```

### Operational utilities

| Module                 | Description                                          |
|------------------------|------------------------------------------------------|
| `llx.repr`             | Single-line, Lua-valid string representations        |
| `llx.pretty`           | Multi-line pretty-printer with cycle detection       |
| `llx.tostringf`        | Composable string formatting via `__tostringf`       |
| `llx.tointeger`        | Safe integer coercion with overflow checks           |
| `llx.truthy`           | Type-based truthiness (0 and '' are falsey)          |
| `llx.hash` / `hash_table` | FNV-1a hashing, value-keyed lookup table          |
| `llx.string_view`      | Non-copying substring views                          |
| `llx.proxy`            | Transparent value-wrapping proxy                     |
| `llx.cache`            | Memoization decorator                                |
| `llx.decorator`        | Base class for method decorators                     |
| `llx.coroutine`        | Coroutine-wrapping decorator                         |
| `llx.method`/`signature` | Type-annotated method decorators                  |
| `llx.debug`            | Value dumping, terminal colors, stack traces         |

## API conventions

### Module access

llx uses two patterns for sub-module exposure:

- **Flattened classes** like `llx.List`, `llx.Set`, `llx.Counter`,
  `llx.Deque`, `llx.OrderedDict`, `llx.DefaultDict`, `llx.Heap`,
  `llx.HashTable`, `llx.Tuple`, `llx.Result`, `llx.Option`, `llx.Seq`,
  `llx.StringView`. These are the most-used named types.
- **Named sub-modules** like `llx.functional`, `llx.mathx`,
  `llx.bisect`, `llx.path`, `llx.pretty`, `llx.contextlib`,
  `llx.exceptions`, `llx.flow_control`. These hold related functions
  rather than a single class.

### Callback shapes

`List` methods and `llx.functional` functions both accept callbacks
but call them differently:

| Source                          | Callback receives              |
|---------------------------------|--------------------------------|
| `list:map(f)`, `list:filter(f)` | `f(value, index)`              |
| `list:reduce(f, init)`          | `f(accumulator, value, index)` |
| `functional.map(f, seq)`        | `f(value)` per single sequence |
| `functional.filter(f, seq)`     | `f(value)`                     |
| `functional.reduce(seq, f, i)`  | `f(accumulator, value)`        |
| `Seq:map(f)`, `Seq:filter(f)`   | `f(value)`                     |

Callbacks targeting `functional`/`Seq` also work with `list:map`
(Lua drops the extra index argument). The reverse is usually fine
because Lua ignores the missing index.

### Argument order in `llx.functional`

Two patterns coexist by intent:

- **Operations** (transformations) put the *function first*, sequence
  second: `map(f, seq)`, `filter(pred, seq)`, `take_while(pred, seq)`,
  `find(pred, seq)`, `flatmap(f, seq)`, `interpose(sep, seq)`.

- **Reductions and aggregations** (consumers) put the *sequence first*,
  function second: `reduce(seq, f, init)`, `accumulate(seq, f, init)`,
  `min_by(seq, key)`, `group_by(seq, key)`, `distinct(seq, key)`,
  `scan(seq, f, init)`, `index_by(seq, key)`, `chunk_by(seq, key)`,
  `take_last(seq, n)`, `drop_last(seq, n)`.

In operations, the function is the most variant argument and sequences
thread through unchanged; in reductions, the sequence is the subject
and the function describes *how* to fold over it.

### Eager vs lazy in `llx.functional`

Most `llx.functional` functions are lazy: they return an iterator
that pulls from input on demand. Some materialize the input into a
`List` before producing any output.

**Inherently eager** (semantics require the full input):
`group_by`, `distinct`, `shuffle`, `sample`, `sorted`, `combinations`,
`permutations`, `cycle`, `unzip`, `partition`, `reduce_right`,
`index_by`, `chunk_by`, `take_last`, `drop_last`.

**Eager today, may become lazy later**:
`accumulate`, `sliding_window`, `interleave`, `peekable`, `split_when`,
`unique_justseen`, `take_nth`, `scan`, `zip_with`.

Eager functions are unsafe to feed with infinite iterators (`count`,
`cycle`, `iterate`, `repeat_elem` without `times`) unless bounded by
`slice` or `take_while` first. Each eager function is marked with
`@note Eager` in its inline docstring.

### Custom types should follow regularity rules

For types you define yourself, when you implement `__eq` also
implement `__hash` so the type works as a `HashTable` key; when you
implement `__lt` derive `__le` from it (`a <= b` iff `not (b < a)`)
to keep ordering consistent. Most llx-defined types follow this
convention.

## Companion libraries

llx is intentionally focused. The areas below are covered well by
existing LuaRocks packages and llx does not duplicate them.

| Need                       | Recommended                                        |
|----------------------------|----------------------------------------------------|
| JSON encode/decode         | [`lua-cjson`](https://luarocks.org/modules/openresty/lua-cjson) (C, fast) or [`dkjson`](https://dkolf.de/dkjson-lua/) (pure Lua) |
| Filesystem ops (lfs)       | [`LuaFileSystem`](https://lunarmodules.github.io/luafilesystem/) — actively maintained, ships dir listing, stat, attributes |
| Regex / parsing            | [`LPeg`](http://www.inf.puc-rio.br/~roberto/lpeg/) + its `re` module by Roberto Ierusalimschy |
| CLI argument parsing       | [`argparse`](https://github.com/mpeterv/argparse) by mpeterv (Python-style, full-featured) |
| Logging                    | [`LuaLogging`](https://github.com/lunarmodules/lualogging) by lunarmodules (log4j-style appenders) |
| Date/time with timezones   | [`luatz`](https://github.com/daurnimator/luatz) by daurnimator |
| Simple dates               | [`LuaDate`](https://tieske.github.io/date/) by tieske |
| HTTP                       | [`lua-http`](https://github.com/daurnimator/lua-http) (modern) or `luasocket.http` (older) |
| Testing (when llx.unit isn't enough) | [`busted`](https://lunarmodules.github.io/busted/) by lunarmodules |

Install whichever ones you need alongside llx; nothing here is
required, and llx itself only depends on Lua 5.4.

## Not included (and why)

Areas deliberately out of scope. Use external libraries or write your
own:

- **Crypto hashes (SHA-256, bcrypt, Argon2).** `llx.hash` is FNV-1a
  for value-equality lookups, not cryptography. Use a dedicated
  crypto library when you need password hashing or content addressing.
- **Asynchronous I/O / Promise / async-await.** Lua's `coroutine` is
  the substrate; building a full event loop and Promise API is its
  own library. Use `cqueues` or the OpenResty ecosystem if needed.
- **OS-level threading and multiprocessing.** Lua is single-threaded.
  Coroutines cover cooperative concurrency; for parallelism use
  `lua-llthreads2` or your host language's threading.
- **Network protocols (HTTP, WebSocket, gRPC).** Use the companion
  libraries above.
- **Databases / SQL.** Use `luasql`, `lsqlite3`, or a driver for your
  database.
- **Date / time arithmetic.** Use `luatz` or `LuaDate`.
- **JSON / YAML / TOML / CSV / pickle.** Serialization is its own
  domain; use a dedicated library.
- **Regex (PCRE-style).** Lua patterns are weaker than PCRE; for
  serious parsing, use LPeg.
- **Filesystem directory listing, stat, attributes, glob.** `llx.path`
  covers manipulation and basic read/write. For directory iteration,
  file metadata, or path globbing, pair with `LuaFileSystem`.
- **CLI argument parsing.** Use `argparse` (mpeterv).
- **Logging frameworks with levels and appenders.** Use `LuaLogging`.
- **Pretty stack traces with source context, color, locals.**
  `llx.debug` covers value dumping and simple traces; for richer
  output use something dedicated.
- **C-side bindings to system libraries.** llx is pure Lua.

The general principle: llx provides primitives that don't exist or
are weak elsewhere in the Lua ecosystem (class system, value-equality
collections, sum types, schema validation, structured exceptions),
and stays out of areas already covered by mature, well-maintained
packages.

## Conventions for project structure

Test files live in `tests/` mirroring `src/`. Tests use the built-in
`llx.unit` BDD framework. New test files must be registered in
`tests/init.lua`.

Examples live in `examples/` — each is a self-contained, runnable
demonstration of one area of the library.

Benchmarks live in `benchmarks/` — run with
`lua5.4 benchmarks/run.lua` to time hot paths.

Type stubs for the sumneko / Lua Language Server live in `stubs/`.
Add to your `.luarc.json` `workspace.library` for editor completion.

## Running tests

llx modules must be installed before tests can resolve them:

```sh
luarocks make --local && lua test.lua
```

On systems where `lua` defaults to an older version, use `lua5.4`
explicitly. If module resolution fails despite the install, prepend
the luarocks paths:

```sh
eval "$(luarocks-5.4 path)" && lua5.4 test.lua
```

## Requirements

- Lua 5.4 or later
- No external runtime dependencies

## License

MIT License — see [LICENSE](LICENSE) for details.

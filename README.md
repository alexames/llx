# llx - Lua Extension Library

A comprehensive utility library for Lua 5.4+ that brings object-oriented programming, functional programming, type checking, exception handling, and more to Lua development.

## Installation

Install via [LuaRocks](https://luarocks.org) using the custom server:

```sh
luarocks install llx --server=https://alexames.github.io/luarocks-repository
```

Or clone the repository and add `src/` to your Lua package path:

```sh
git clone https://github.com/alexames/llx.git
```

## Quick Start

```lua
local llx = require 'llx'
local class = llx.class
local functional = require 'llx.functional'
```

## Features

### Class System

Create classes with inheritance.

```lua
local Animal = class 'Animal' {
  __init = function(self, name)
    self._name = name
  end,

  get_name = function(self)
    return self._name
  end,
}

local Dog = class 'Dog' : extends(Animal) {
  __init = function(self, name, breed)
    self.Animal.__init(self, name)
    self._breed = breed
  end,

  speak = function(self)
    return self:get_name() .. ' says woof!'
  end,
}

local dog = Dog('Rex', 'Labrador')
print(dog:get_name()) --> Rex
print(dog:speak())    --> Rex says woof!
```

### Functional Programming

Iterator-based utilities inspired by Python's itertools.

```lua
local f = require 'llx.functional'

-- Range, map, filter, reduce
for i, v in f.range(1, 10) do print(v) end

local squares = f.collect(f.map(function(i, v) return v * v end, f.range(5)))
-- {1, 4, 9, 16}

local evens = f.collect(f.filter(function(i, v) return v % 2 == 0 end, f.range(10)))
-- {2, 4, 6, 8}

local sum = f.reduce(function(acc, i, v) return acc + v end, 0, f.range(100))

-- Combinators
local add_one = f.partial(function(a, b) return a + b end, 1)
local pipeline = f.pipe(add_one, tostring)
```

### Exception Handling

Structured exceptions with try-catch.

```lua
local exceptions = require 'llx.exceptions'
local flow = require 'llx.flow_control'

local ValueError = exceptions.ValueError

flow.try {
  function()
    error(ValueError('invalid input'))
  end;
  flow.catch(ValueError, function(e)
    print('Caught:', e)
  end);
}
```

### Type System & Schema Validation

Runtime type checking and schema validation.

```lua
local llx = require 'llx'

print(llx.isinstance(42, llx.Integer))     --> true
print(llx.isinstance('hi', llx.String))    --> true

local schema = llx.Schema {
  name = llx.String,
  age = llx.Integer,
}
llx.matches_schema(schema, { name = 'Alice', age = 30 })
```

### Extended Math

Statistical functions and numeric utilities.

```lua
local mathx = require 'llx.mathx'

mathx.clamp(15, 0, 10)          --> 10
mathx.lerp(0, 100, 0.5)         --> 50
mathx.mean(2, 4, 6, 8)          --> 5
mathx.median(1, 3, 5, 7, 9)     --> 5
mathx.stdev(2, 4, 4, 4, 5, 5, 7, 9) --> ~2.0
mathx.gcd(12, 8)                 --> 4
mathx.round(3.7)                 --> 4
```

### Operators as Functions

First-class operator functions for use with higher-order functions.

```lua
local ops = require 'llx.operators'
local f = require 'llx.functional'

local sum = f.reduce(function(acc, i, v) return ops.add(acc, v) end, 0, f.range(10))
local getter = ops.itemgetter('name')
local attr = ops.attrgetter('config.debug')
```

### Enumerations

```lua
local llx = require 'llx'

local Color = llx.enum 'Color' {
  'Red', 'Green', 'Blue',
}

print(Color.Red)         --> Red
print(Color[1])          --> Red
```

### Unit Testing

Built-in BDD-style test framework with mocks and spies.

```lua
local unit = require 'llx.unit'

unit.describe('my module', function()
  unit.before_each(function()
    -- setup
  end)

  unit.it('should do something', function()
    unit.expect(1 + 1).to.equal(2)
    unit.expect('hello').to.be_truthy()
  end)

  unit.it('should raise on bad input', function()
    unit.expect(function()
      error('bad')
    end).to.raise_error()
  end)
end)

unit.run_tests()
```

### Additional Utilities

| Module                | Description                                                  |
|-----------------------|--------------------------------------------------------------|
| `llx.repr`            | Lua-valid string representations of values                   |
| `llx.truthy`          | Truthiness/falseyness testing                                |
| `llx.tuple`           | Immutable value tuples with equality and hashing             |
| `llx.hash`            | FNV-1a value hashing                                         |
| `llx.hash_table`      | Hash-based lookup table using value equality                 |
| `llx.proxy`           | Transparent value-wrapping proxy objects                     |
| `llx.string_view`     | Non-copying string views                                     |
| `llx.cache`           | Method result memoization decorator                          |
| `llx.decorator`       | Base class for method decorators                             |
| `llx.check_arguments` | Function argument validation                                 |
| `llx.debug`           | Debug printing, value dumping, stack traces, terminal colors |
| `llx.strict`          | Prevents accidental global variable creation                 |
| `llx.coroutine`       | Coroutine-wrapping decorator                                 |
| `llx.bytecode`        | Low-level Lua 5.4 bytecode manipulation                      |

## Module Structure

```
llx
├── core              -- Fundamental utilities (predicates, comparisons, iterators)
├── class             -- OOP class system with inheritance and properties
├── functional        -- Functional programming (itertools-inspired)
├── operators         -- Operator functions
├── mathx             -- Extended math and statistics
├── types/            -- Type classes (Integer, String, List, Set, etc.)
├── exceptions/       -- Exception hierarchy (ValueError, TypeError, etc.)
├── flow_control/     -- try/catch, switch/case
├── unit/             -- Unit testing framework with mocks
├── debug/            -- Debugging utilities
├── strict/           -- Strict mode for globals
└── bytecode/         -- Bytecode manipulation
```

## API Conventions

### Callback signatures

`List` methods and `llx.functional` functions both accept callbacks, but
they call them with different argument shapes. Code that targets one
will not always work transparently against the other.

| Source                          | Callback receives        |
|---------------------------------|--------------------------|
| `list:map(f)`, `list:filter(f)` | `f(value, index)`        |
| `list:reduce(f, init)`          | `f(accumulator, value, index)` |
| `functional.map(f, seq)`        | `f(value)` per sequence (or `f(unpack(values))` for multiple sequences) |
| `functional.filter(f, seq)`     | `f(value)`               |
| `functional.reduce(seq, f, i)`  | `f(accumulator, value)`  |

If a callback works with `list:map`, it generally also works with
`functional.map` because Lua silently drops the extra `index` argument
the method form would have passed. The reverse is not always true: if a
`functional`-shaped callback expects only `value`, it still works when
called by `list:map` (Lua ignores the extra index).

### Argument order in `llx.functional`

Two patterns coexist by intent:

- **Operations** that transform a sequence put the *function first*,
  the sequence second:
  `map(f, seq)`, `filter(pred, seq)`, `take_while(pred, seq)`,
  `drop_while(pred, seq)`, `find(pred, seq)`, `find_index(pred, seq)`,
  `partition(pred, seq)`, `flatmap(f, seq)`.

- **Reductions and aggregations** that consume a sequence put the
  *sequence first*, the function (if any) second:
  `reduce(seq, f, init)`, `accumulate(seq, f, init)`,
  `min_by(seq, key)`, `max_by(seq, key)`, `sort_by(seq, key)`,
  `group_by(seq, key)`, `distinct(seq, key)`, `scan(seq, f, init)`,
  `reduce_right(seq, f, init)`, `unique_justseen(seq, key)`.

The split is deliberate: in operations, the function is the most
variant argument and sequences thread through unchanged; in reductions,
the sequence is the subject and the function describes *how* to fold
over it.

### Eager vs lazy iteration

Most `llx.functional` functions are lazy: they return an iterator that
pulls from the input on demand. Some materialize the input into a
`List` before producing any output. Functions whose semantics require
the full input (`group_by`, `distinct`, `shuffle`, `sample`, `sorted`,
`combinations`, `permutations`, `cycle`, `unzip`, `partition`,
`reduce_right`) are inherently eager. Other functions
(`accumulate`, `sliding_window`, `interleave`, `peekable`,
`split_when`, `unique_justseen`, `take_nth`, `scan`, `zip_with`) are
implemented eagerly today and may become lazy in a future release.

Eager functions are unsafe to use with infinite iterators
(e.g. `count`, `cycle`, `iterate`, `repeat_elem`) without first
bounding the input via `slice` or `take_while`.

## Running Tests

```sh
lua test.lua
```

## Requirements

- Lua 5.4 or later
- No external dependencies

## License

MIT License - see [LICENSE](LICENSE) for details.

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
├── bytecode/         -- Bytecode manipulation
└── experimental/     -- Experimental features
```

## Running Tests

```sh
lua test.lua
```

## Requirements

- Lua 5.4 or later
- No external dependencies

## License

MIT License - see [LICENSE](LICENSE) for details.

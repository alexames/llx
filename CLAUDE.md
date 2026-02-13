# llx - Lua Extension Library

A comprehensive utility library for Lua 5.4+ providing OOP, functional programming,
type checking, exception handling, unit testing, and more.

## Project Structure

```
src/                  Source modules (mapped to llx.* via rockspec)
  init.lua            Entry point (require 'llx')
  class.lua           OOP class system with inheritance
  core.lua            Fundamental utilities (predicates, comparisons, iterators)
  functional.lua      Functional programming (itertools-inspired iterators)
  hash.lua            FNV-1a value hashing with __hash metamethod support
  tuple.lua           Immutable value tuples
  types/              Collection types (List, Set, Table, String) and type classes
  exceptions/         Exception hierarchy (ValueError, TypeError, etc.)
  flow_control/       try/catch, switch/case
  unit/               BDD-style unit testing framework with mocks
  debug/              Debug printing, value dumping, terminal colors
  strict/             Strict mode preventing accidental globals
  bytecode/           Lua 5.4 bytecode reader
tests/                Test files, mirroring src/ structure
  init.lua            Registers all test modules
test.lua              Test runner entry point
llx-scm-1.rockspec   LuaRocks package spec (defines module-to-file mapping)
```

## Install

Requires Lua 5.4+ and LuaRocks.

```sh
luarocks make --local
```

This installs the library from the local source into `~/.luarocks/` (or the
platform equivalent), making `require 'llx'` and all submodules available.

## Running Tests

The rockspec maps `llx.*` to `src/*`, so modules must be installed before tests
can resolve `require 'llx.unit'`, etc. Always install before testing:

```sh
luarocks make --local && lua test.lua
```

On Windows, if `lua test.lua` fails to find modules despite installation, you
may need to prepend the luarocks install path explicitly. Find it with
`luarocks path` and pass it via `lua -e`:

```sh
luarocks make --local && lua -e "package.path=luarocks_share_path .. package.path; dofile('test.lua')"
```

## Test Conventions

- Test files live in `tests/` and mirror the `src/` directory structure.
- Tests use the built-in `llx.unit` BDD framework: `describe`, `it`, `expect`.
- New test files must be registered in `tests/init.lua` via `require`.
- Test files are also independently runnable:
  ```lua
  if llx.main_file() then
    unit.run_unit_tests()
  end
  ```

## Code Conventions

- Modules use `llx.environment.create_module_environment()` to create isolated
  `_ENV` tables, exporting public symbols via the returned `_M` table.
- Classes are defined with `class 'Name' { ... }` and support inheritance via
  `: extends(Base)`.
- Types that define `__eq` should also define `__hash` (and ideally `__tostring`,
  `__len` where applicable) for type regularity.
- Comparison operators (`__lt`, `__le`) should be defined in terms of `<` only
  (not `>`), per Elements of Programming conventions.
- `lesser`/`greater` (in `core.lua`) are stable: `lesser` returns the first
  argument when equal, `greater` returns the second.

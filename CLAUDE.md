# llx - Lua Extension Library

A comprehensive utility library for Lua 5.3+ providing OOP, functional programming,
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

Requires Lua 5.3+ and LuaRocks.

```sh
luarocks make --local
```

This installs the library from the local source into `~/.luarocks/` (or the
platform equivalent), making `require 'llx'` and all submodules available.

## Running Tests

The aggregate runner is self-sufficient: `test.lua` installs a package
searcher that resolves `llx.*` from `src/` and `llx.tests.*` from `tests/`
relative to itself, so it runs the full suite straight from a checkout with
no installation or `LUA_PATH` setup, and always tests the checkout sources
(never a stale installed rock):

```sh
lua test.lua
```

Running a single test file standalone (as CI does per file) still resolves
`llx.*` through the normal package path, so it needs the rock installed and
visible. Install with `luarocks make --local`; if the interpreter's default
`package.path` does not include the LuaRocks tree, prepend it (find it with
`luarocks path --lr-path`):

```sh
# sh / bash
LUA_PATH="$(luarocks path --lr-path);;" lua tests/test_core.lua
```

```powershell
# PowerShell
$env:LUA_PATH = "$(luarocks path --lr-path);;"; lua tests/test_core.lua
```

## Test Conventions

- Test files live in `tests/` and mirror the `src/` directory structure.
- Tests use the built-in `llx.unit` BDD framework: `describe`, `it`, `expect`.
- New test files must be registered in `tests/init.lua` via `require`.
- Test files are also independently runnable:
  ```lua
  if llx.main_file() then
    os.exit(unit.run_unit_tests() == 0)
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

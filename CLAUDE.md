# llx - Lua Extension Library

A comprehensive utility library for Lua 5.1 through 5.5 and LuaJIT, providing OOP,
functional programming, type checking, exception handling, unit testing, and more.

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
  bytecode/           Lua 5.4/5.5 bytecode readers (need Lua 5.3+)
  compat/             Per-version layers behind llx.compat (see below)
tests/                Test files, mirroring src/ structure
  init.lua            Registers all test modules
  lua53/              Tests that need Lua 5.3+ syntax, mirroring tests/
  support/            Test helpers that are not tests (lua_features lexer)
test.lua              Test runner entry point
llx-scm-1.rockspec   LuaRocks package spec (defines module-to-file mapping)
llx-luajit-scm-1.rockspec  The same modules, declared against LuaJIT
```

## Install

Requires Lua 5.1+ (or LuaJIT) and LuaRocks.

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

## Supported Lua Versions

llx runs on Lua 5.1, 5.2, 5.3, 5.4, 5.5 and LuaJIT 2.x. Run the suite on
each interpreter a change can affect (`lua5.1 test.lua`, `luajit test.lua`,
...); `tests/test_portability.lua` fails on any of them when a source uses
syntax or a library name that an interpreter loading it lacks.

- **Shared code is written in the Lua 5.1 syntax subset**: no `goto`, no
  `\x`/`\z` escapes, no integer operators (`//`, `&`, `|`, `~`, `<<`,
  `>>`), no `<const>`/`<close>`.
- **Version-specific behaviour goes through `llx.compat`**, never a
  version check in shared code. `llx.compat` loads one layer for the
  running interpreter; each layer file runs only on its versions and may
  use their syntax and globals:

  | Layer                 | Loaded on    | Extends    |
  |-----------------------|--------------|------------|
  | `compat/portable.lua` | everywhere   | --         |
  | `compat/lua51.lua`    | 5.1, LuaJIT  | portable   |
  | `compat/luajit.lua`   | LuaJIT       | lua51      |
  | `compat/lua52.lua`    | 5.2+         | portable   |
  | `compat/lua53.lua`    | 5.3+         | lua52      |

  A new operation goes into every layer that needs its own form, with the
  portable or oldest form in the base and overrides above it.
  `portable.lua` holds pure-Lua algorithms and must reach no
  version-specific name.
- **Use `compat.*` instead of** `table.unpack`/`table.pack`/`unpack`,
  `load`/`loadfile` with an environment, `math.type`, `string.pack`, the
  bitwise operators, and `string.format` (5.1's `%s` rejects tables); and,
  on any value that may be an llx object, instead of `pairs`
  (`compat.pairs`) and `#` (`compat.len`), since Lua 5.1 and a default
  LuaJIT ignore `__pairs` and `__len` on tables.
- **Before 5.3, `==`, `<` and `<=` consult a metamethod only when both
  operands carry the same function.** Define a comparison metamethod once
  and share it, not per object, and compare values that may carry
  different metatables with `compat.equals`.
- **Metamethods that only later versions call** are attached through a
  helper that is a no-op where they do not exist:
  `compat.add_integer_operator_metamethods(mt, unwrap)`,
  `compat.add_name_tostring(mt)`.
- **An API spelled with an operator gets a named form** that works
  everywhere: `flag:union(other)` for `flag | other`.
- A test that needs Lua 5.3+ syntax goes in `tests/lua53/`, mirroring the
  path of the file it belongs with, and is required from the gated block
  in `tests/init.lua`. A test of behaviour a version lacks (the integer
  subtype, mixed-type `__lt`) passes `not compat.<flag>` as `it`'s third
  argument, which skips it there.
- Both rockspecs list the same modules; a test checks it.

## Test Conventions

- Test files live in `tests/` and mirror the `src/` directory structure.
- Tests use the built-in `llx.unit` BDD framework: `describe`, `it`, `expect`.
- New test files must be registered in `tests/init.lua` via `require`.
- Test files are also independently runnable:
  ```lua
  if llx.main_file() then
    os.exit(unit.run_unit_tests() == 0 and 0 or 1)
  end
  ```

## Code Conventions

- Modules use `llx.environment.create_module_environment()` to create isolated
  `_ENV` tables, exporting public symbols via the returned `_M` table. The
  `local _ENV, _M = ...` line stays at the chunk's top level: on Lua 5.1 and
  LuaJIT the environment is installed with `setfenv` on the calling chunk.
- Classes are defined with `class 'Name' { ... }` and support inheritance via
  `: extends(Base)`.
- Types that define `__eq` should also define `__hash` (and ideally `__tostring`,
  `__len` where applicable) for type regularity.
- Comparison operators (`__lt`, `__le`) should be defined in terms of `<` only
  (not `>`), per Elements of Programming conventions.
- `lesser`/`greater` (in `core.lua`) are stable: `lesser` returns the first
  argument when equal, `greater` returns the second.

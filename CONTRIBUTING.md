# Contributing to llx

Thanks for your interest in improving llx! This guide covers the development
setup, how to run the tests, and how to submit a change.

## Requirements

- Lua 5.3 or later (5.3, 5.4, and 5.5 are all supported and tested)
- [LuaRocks](https://luarocks.org/)

There are no external runtime dependencies.

## Development setup

The rockspec maps `llx.*` to files under `src/`, so the library must be
installed into your local rocktree before tests can resolve `require 'llx.unit'`
and friends. Install from the local source with:

```sh
luarocks make --local
```

Re-run this after adding or renaming a module (and add the module to the
`build.modules` table in `llx-scm-1.rockspec`).

## Running the tests

```sh
luarocks make --local && lua test.lua
```

On systems where `lua` points at an older interpreter, call `lua5.4`
explicitly. If module resolution fails despite the install, prepend the
LuaRocks paths:

```sh
eval "$(luarocks path)" && lua5.4 test.lua
```

The suite should report **all tests passed** with zero failures. Please run it
on Lua 5.3, 5.4, and 5.5 if you have them available. Avoid Lua 5.4+ only syntax
(`<close>`, `<const>`) in library source and tests so everything keeps parsing
on 5.3; where a feature genuinely needs it, compile that snippet at runtime with
`load(...)` and skip when it returns nil.

## Test conventions

- Test files live in `tests/`, mirroring the `src/` directory structure.
- Tests use the built-in `llx.unit` BDD framework: `describe`, `it`, `expect`.
- New test files must be registered in `tests/init.lua` via `require`.
- Assert on the specific error, not just that *something* throws — prefer
  `pcall` + a message/type assertion over a bare `.to.throw()` so a wrong-but-
  still-throwing code path can't pass silently.
- Test files are independently runnable:

  ```lua
  if llx.main_file() then
    os.exit(unit.run_unit_tests() == 0)
  end
  ```

## Code conventions

- Modules use `llx.environment.create_module_environment()` to create an
  isolated `_ENV`, exporting public symbols via the returned `_M` table.
- Define classes with `class 'Name' { ... }`; use `: extends(Base)` for
  inheritance.
- Types that define `__eq` should also define `__hash` (and ideally
  `__tostring` and `__len` where applicable) for regularity.
- Define comparison operators (`__lt`, `__le`) in terms of `<` only.
- Document every public symbol with an LDoc comment (purpose, `@param`,
  `@return`, and any errors raised).

## Submitting a pull request

1. Fork the repository and create a topic branch.
2. Make your change, adding or updating tests to cover it. A bug fix should
   come with a regression test that would have failed before the fix.
3. Ensure `lua test.lua` passes.
4. Update `CHANGELOG.md` under the `[Unreleased]` section.
5. Open a pull request describing the motivation and the change.

By contributing, you agree that your contributions are licensed under the
project's [MIT License](LICENSE).

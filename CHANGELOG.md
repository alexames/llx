# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Breaking:** `Signature`-wrapped functions now enforce arity. Calls
  with more arguments than declared in `params`, and results with more
  values than declared in `returns`, raise `InvalidArgumentException`
  instead of passing silently. Counts are exact (`table.pack`-based),
  so embedded `nil`s are included. To declare a variadic signature, add
  a trailing `'...'` entry to `params` or `returns`: the fixed prefix
  is still type-checked and any number of extra values is allowed.
  Note that methods receive `self`, so a method's `params` list must
  declare it (e.g. `params={'MyClass', Integer}`); `params={}` on a
  method now raises on every call. (#46)
- **Breaking:** `Signature{...}` and `Function{...}` now validate their
  field table at construction: `params` and `returns` must both be
  tables, and a missing or non-table field raises
  `InvalidArgumentException` naming the field instead of crashing later
  inside the call-time checks with a raw "attempt to get length of a
  nil value". Declare an empty list explicitly (`params={}`,
  `returns={}`) or use `{'...'}` for an unchecked variadic list. (#63)

### Fixed

- `tostring` of a `Signature`-wrapped `Function` no longer raises
  "invalid value in table for concat" when `params` or `returns`
  contain matcher tables (e.g. `Integer`, `Optional(String)`); entries
  are now rendered by type name, matching `Overload`'s signature
  descriptions. (#63)

### Added

- `check_returns_exact(expected_types, values, count)` and the
  `VARARG` (`'...'`) marker in `llx.check_arguments`, reusable outside
  the `Signature` wrapper.

## [1.0.0] - 2026-07-05

First tagged release. Requires Lua 5.3 or later; no external runtime
dependencies.

### Added

- **Classes** — `class 'Name' { ... }` with single/multiple inheritance,
  properties, metamethods, named-superclass references, and generated
  `to_Name` conversions.
- **Collections** — value-comparing, value-hashing `List`, `Set`, `Tuple`,
  `Counter`, `Deque`, `OrderedDict`, `DefaultDict`, `Heap`, `HashTable`,
  plus `namedtuple` and `dataclass` records.
- **Sum types** — `Result` (`Ok`/`Err`) and `Option` for non-exceptional
  error handling.
- **Functional programming** — itertools/functools-inspired iterators and a
  chainable `Seq`.
- **Runtime type checking & schema validation** — type singletons,
  `isinstance`, composite matchers (`Union`, `Optional`, `Dict`, `Protocol`),
  and constraint-based `Schema`.
- **Structured exceptions** — an exception hierarchy with captured tracebacks
  and a `try`/`catch` flow-control DSL.
- **Utilities** — `path`, `pretty`, `repr`, `mathx`, `bisect`, `operators`,
  `contextlib`, `enum`/`Flag`, `string_view`, `hash`, and more.
- **Unit testing** — BDD-style `describe`/`it`/`expect` framework with mocks
  and spies.
- **Bytecode reader** — low-level inspection of compiled Lua 5.4 and 5.5
  chunks.

### Known issues

- `llx.bytecode.lua55` targets a pre-release Lua 5.5 chunk header and does not
  yet parse chunks emitted by the final Lua 5.5.0 release (`integer format
  mismatch`). All other modules are fully compatible with Lua 5.4 and 5.5.

[Unreleased]: https://github.com/alexames/llx/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/alexames/llx/releases/tag/v1.0.0

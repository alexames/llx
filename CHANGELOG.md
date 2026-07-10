# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Standalone test files and the aggregate runner `test.lua` now
  propagate test failures into the process exit status: the standard
  footer is `os.exit(unit.run_unit_tests() == 0)` instead of a bare
  `unit.run_unit_tests()` call. Previously a test file run directly
  (as CI does per file) always exited 0, even when assertions failed,
  so only load-time errors could turn CI red and runtime test
  failures merged green. `unit.run_unit_tests()` itself is unchanged
  -- it still returns the failure and test counts and never calls
  `os.exit`, so embedders and aggregate runners are unaffected.
  `tests/test_hygiene.lua` now requires the exit-propagating footer
  form in every test file, so a non-failing footer cannot creep back
  in. (#82)
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
- **Breaking:** `ListOf(T)` no longer vacuously matches tables with an
  empty array part. Matching tables must now be list-shaped: their raw
  keys must be exactly `1..n` for the `ipairs`-covered prefix (no hash
  keys, no holes), and every element must satisfy `T`. The empty table
  `{}` is still accepted (an empty list is `{}` in Lua,
  indistinguishable from an empty dict), and `llx.List` instances are
  unaffected. Previously `{meta = print}` satisfied `ListOf(Integer)`
  because the element loop was vacuous over a hash-only table, so a
  `Union{ListOf(T), Dict(K, V)}` JSON-style matcher could not reject
  hash tables with invalid values; tables mixing hash keys into the
  array part (e.g. `{1, 2, extra = 'x'}`) also matched and are now
  rejected. `SetOf` is unaffected: it requires an `llx.Set` instance,
  so it never had a vacuous path. (#65)

- **Breaking:** `isinstance(value, t)` now raises
  `InvalidArgumentException` naming argument #2 ("expected a type
  matcher or class with `__isinstance`, got ...") when `t` is not a
  type matcher or class -- a plain string, number, `nil`, boolean, or
  table without `__isinstance`. Previously a number, boolean, or
  `nil` `t` crashed with an obscure "attempt to index" error from
  inside the dispatch; a string `t` silently misdispatched through
  the llx string extension (whose `__isinstance` tests whether the
  *value* is a string, so `isinstance(err, 'TypeError')` matched any
  string whatsoever); and a table without `__isinstance` (including
  a bare `Rest(T)` marker) silently returned `false`. The raise
  applies everywhere `isinstance` is used, so malformed type
  arguments that previously failed silently now fail loudly: a
  string catcher in `try`/`catch` (`catch('TypeError', ...)` --
  pass the exception class itself), a non-type `type_switch` case,
  or a non-type `Schema` `type` field. (#67)
- Argument and return mismatch messages now describe class instances
  and class objects explicitly: "Integer expected, got an instance of
  Animal" (previously the bare class name "Animal", ambiguous between
  the class and an instance) and "got the class Animal" when the class
  object itself was passed. The instance-aware description is shared
  (`llx.getclass.describe_value`, with the `is_class_object`
  predicate), so `NewType` constructor rejections and `ClassOf`/`Lazy`
  construction errors report "an instance of Animal" instead of a bare
  "table" too. Messages for primitives and plain tables are unchanged.
  (#67)

### Fixed

- Comparing a `Set` against a plain table (or any table that is not a
  `Set`) with `==` now returns `false` instead of raising "attempt to
  index a nil value" inside `Set.__eq`. (#69)
- String-declared expected types now render as themselves in argument
  mismatch messages: a mismatch against `params={'MyClass'}` reports
  "MyClass expected" instead of "String expected" (the llx string
  extension gives every Lua string `__name == 'String'`, which the
  generic name lookup picked up). (#67)
- `OverloadResolutionException` now anchors its traceback at the
  user's call site instead of `Overload`'s internal dispatch frame in
  `signature.lua`, and per-step failures raised by
  `llx.typed_iterators` wrappers (iterator steps, generator yields,
  sends, and returns) re-anchor their traceback at the first frame
  outside the module -- the loop or call driving the boundary --
  instead of the internal check machinery behind its `pcall`. (#67)
- The unit framework's `throw(expected)` matcher now strips the
  leading `"file:line: "` error-position prefix with a pattern
  anchored on the line number (lazy `^.-:%d+: `) instead of cutting
  through the second colon. Windows absolute chunknames
  (`C:\path\file.lua:123: msg`) previously left part of the path in
  place because the drive-letter colon was counted as the path/line
  separator, and messages with no colon at all crashed the matcher
  with a nil-arithmetic error. Lazy anchoring strips only the
  shortest such prefix, preserving `":N:"` sequences and colons
  inside the message body; when no prefix matches, the raw message
  is compared unchanged. (#66)
- A `Rest(T)` marker placed in a `Signature`/`Function` `params` or
  `returns` list, or in a `Callable` parameter or return type list, now
  raises `ValueException` at declaration/construction time ("Rest(T) is
  only valid inside Tuple; use a trailing VARARG (`'...'`) for variadic
  signatures") instead of being silently unsatisfiable. `Rest` has no
  `__isinstance`, so such a position could never match any value.
  `check_returns_exact` rejects it too, as the call-time backstop for
  type lists that bypass those constructors. `Tuple{..., Rest(T)}`
  is unchanged, and the new `is_rest(value)` predicate is exported
  from `llx.types.matchers`. (#64)
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

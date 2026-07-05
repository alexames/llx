# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

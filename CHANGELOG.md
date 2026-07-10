# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- **Breaking:** `is_subtype` no longer treats two distinct llx
  classes that share a non-anonymous `__name` as equal (and
  therefore as mutual subtypes). Classes carry identity, so they now
  compare by identity plus the declared inheritance hierarchy only,
  closing the name-collision soundness gap documented since #26 for
  direct class comparisons (and, through the structural Tuple rule
  below, for Tuple element types). The name fallback still applies
  where it is relied on by design: separately constructed
  parameterized matchers (`Dict(String, Integer)`,
  `NewType('Brand', T)`, ...) keep comparing equal by name, and
  string type names still match classes and matchers by name.
  Because a container matcher's name embeds only its element types'
  *names*, same-named classes can still be conflated one level up
  inside non-Tuple containers (`Union{C}`, `ListOf(C)`, ...), whose
  comparison remains name-based. (#73)
- `is_subtype` now compares two `Tuple` matchers structurally --
  element-wise covariantly, with fixed/variadic arity rules
  mirroring `signature_compatible`'s return-list rules -- instead of
  by name only. `Tuple{Integer, Integer}` is now a subtype of
  `Tuple{Integer, Rest(Integer)}`, and `Tuple{Rest(Integer)}` of
  `Tuple{Rest(Number)}`; a variadic tuple is not a subtype of a
  fixed one, and the unchecked `'...'` tail behaves as a tail of
  `Any` on both sides. The structural verdict is final: two Tuple
  matchers never fall back to name equality, so tuples over
  distinct same-named classes are no longer conflated through their
  spelled names. (#73)
- `is_subtype` now raises a clear "cyclic type comparison" error
  when a comparison's outcome depends on itself, instead of
  recursing without bound (previously a stack overflow at check
  time). This happens when a type contains itself as a *direct*
  member through `Lazy` -- e.g. a Lazy union containing only itself
  -- and the comparison reaches that member; every such input
  previously diverged. Recursive types that route the recursion
  through a container matcher, which is a leaf of the relation
  (e.g. a JSON-style union over scalars, `ListOf`, and `Dict`
  members), are unaffected. Compare two separately constructed
  recursive types by identity (the same matcher object) rather than
  by structure. (#73)

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
- `signature_compatible` (and therefore the `Callable` matcher) now
  understands variadic declarations: a trailing `'...'` in a
  parameter or return list participates soundly in the variance
  rules. On the parameter side a variadic function can stand in for
  a fixed signature that covers its checked prefix, but a fixed
  function cannot stand in for a variadic one; the return side
  mirrors this (a fixed return list satisfies a variadic
  expectation, while a variadic return list cannot satisfy a fixed
  one). (#52)
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
- `TypeVar` binding refinements, completing three gaps documented in
  the first iteration (#49):
  - Speculative matcher branches now roll back: a `Union` member
    (including `Optional`) that binds a type variable and then
    rejects the value restores the bindings in place before the
    branch, so union member order is no longer observable through
    stale bindings and `Union{ListOf(T), Any}` no longer constrains
    the rest of the call with a binding from a rejected list.
  - Witnesses inside `pairs`-iterated containers (`Dict`, `SetOf`)
    now bind order-independently: the variable binds the join (least
    common supertype) of all witnesses it sees, computed over the
    whole accumulated witness set -- `Integer`/`Float` widen to
    `Number`, subclass mixes bind their most derived common declared
    ancestor (unrelated classes fall back to `Table`), and witness
    sets with no join are rejected in every iteration order. This
    removes the previous nondeterminism and also accepts
    subclass-heterogeneous containers that first-witness binding
    only accepted by iteration-order luck. The join extends through
    nested containers (`Dict(String, ListOf(T))` joins across and
    within its lists, since the outer `pairs` order decides which
    list is checked first). Positional contexts outside such
    containers (`params`, `returns`, and the ipairs-ordered
    `ListOf`/`Tuple`) keep the documented first-witness, one-pass
    binding, so e.g. `params={T, T}` still rejects `f(1, 1.5)`.
  - `check_arguments` and `type_check_decorator` now open the same
    TypeVar binding scopes `llx.signature` threads through wrapped
    calls, so type variables correlate across parameters on those
    paths too (and, for `type_check_decorator`, between arguments
    and returns) instead of degrading to bound-or-`Any` semantics
    per position. (#72)

### Fixed

- `isinstance(wrapped, llx.Function)` (the `types.Function` type
  singleton) now accepts `Signature`-wrapped functions. Annotating a
  function with `Signature` replaces it with a callable table, so
  `Protocol` shapes and `check_arguments` declarations expecting
  `Function` previously rejected signature-annotated members.
  Arbitrary tables with a `__call` metamethod are still rejected.
  (#34)
- `tostring(llx.Boolean)` now returns `'Boolean'` instead of a raw
  table address: the type singleton declared `__tostring` (and
  `__call`) but never installed them in a metatable, which broke any
  matcher embedding `Boolean` in its construction-time name (e.g.
  `Union{Integer, Boolean}`). (#54)
- Matcher type names no longer conflate string-typed entries: the
  matchers' internal name rendering previously sent string type names
  (including the `'...'` marker) through the extended string
  library's `__name`, displaying them all as `String`, which could
  conflate distinct `Callable` matcher names under `is_subtype`'s
  name-equality fallback. (#55)
- The aggregate test runner `lua test.lua` now works from a source
  checkout. It previously required `llx.tests`, which the rockspec
  never installs and nothing mapped to the local `tests/` tree, so
  the documented workflow failed on any machine whose interpreter did
  not already resolve it. `test.lua` now installs a package searcher
  that resolves `llx.*` from `src/` and `llx.tests.*` from `tests/`
  relative to itself, so the full suite runs with no installation or
  `LUA_PATH` setup and always tests the checkout sources rather than
  a possibly stale installed rock. The subprocess spawned by the
  "should not pollute stdout on require" test likewise resolves llx
  from the checkout and reuses the running interpreter instead of
  hardcoding `lua5.4` with an installed rock. Standalone per-file
  test runs still resolve `llx.*` through the normal package path
  and need the rock installed and visible, as before. (#71)
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

- `AnyParams`: the "any parameters" escape hatch for `Callable`, the
  runtime analog of mypy's `Callable[..., R]`. Passed in place of the
  parameter list -- `Callable(AnyParams, {R})` -- it declares that
  parameters are not checked at all: every raw function is accepted
  regardless of arity, every declared parameter list is compatible in
  `signature_compatible` (whichever side declares it), and only
  returns are compared. Like `Any`, this is deliberately gradual
  rather than sound. It is distinct from `Callable({'...'}, {R})`,
  which requires the matched function to itself be variadic, and the
  two forms render differently (`Callable<* -> (R)>` vs
  `Callable<(...) -> (R)>` -- the bare, unparenthesized `*` is not
  producible by any entry name) so `is_subtype`'s name fallback
  never conflates them. `AnyParams` is params-only and
  `Callable`-only: combining it with `{strict = true}`, passing it
  as (or inside) a return list, or embedding it inside a type list
  raises at construction; `Signature`/`Function` declarations reject
  it (as a field or an entry) the same way, since a declared
  signature enforces its lists at call time and cannot enforce
  nothing-in-particular; and `signature_compatible` treats an
  `AnyParams` return list in a plain contract table as malformed
  (compatible with nothing). `is_any_params(v)` recognizes the
  sentinel. (#74)
- `Iterator(..., {strict = true})`: a strict mode for the `Iterator`
  matcher, the iterator analog of `Callable`'s strict option. By
  default raw functions and unwrapped callables match `Iterator`
  structurally (they carry no per-step type information -- the
  documented weak fallback); with a trailing `{strict = true}`
  options table that fallback is disabled entirely, so only values
  that declare their yields -- `Yields{...}`-wrapped iterators and
  generic-for-terminable typed generators -- can match, compared
  covariantly exactly as in lenient mode. Where `Callable`'s strict
  tightens the raw-function check to the strongest available signal
  (exact arity), an iterator has no arity signal at all, so the
  strongest tightening is to require a declaration. Strictness is
  part of the matcher's name (`Iterator<T> strict`). Unknown option
  keys, a non-boolean `strict`, and an empty trailing table (neither
  a usable yield type nor meaningful options) raise at construction.
  (#74)
- `Iterator` and `Generator` now reject stray `Rest(T)` and
  `AnyParams` markers in their declared type lists at construction
  (the policy `Callable` already applies): such an entry was
  silently unsatisfiable against declared yields/contracts while the
  structural fallback still accepted every raw function or thread.
  (#74)
- `Never` is now the bottom type of the `is_subtype` relation:
  `is_subtype(Never, T)` is true for every type `T`, matching its
  documented role as the counterpart of `Any` (an empty `Union` was
  already vacuously a subtype of everything). In the other
  direction nothing but `Never` itself and uninhabited unions
  (`Union{}`, `Union{Never}`) are subtypes of `Never`. TypeVars
  remain excluded from the relation entirely, so
  `is_subtype(Never, T)` for a TypeVar `T` stays false. (#73)
- `llx.signature` is now reachable from the root module as a named
  submodule (`llx.signature.Signature`, `llx.signature.Overload`,
  `llx.signature.Function`), matching sibling submodules like
  `llx.decorator` and `llx.functional`. It is attached as a namespace
  rather than flattened because `llx.signature.Function` would collide
  with the root-level `Function` from `llx.types`. Requiring
  `'llx.signature'` directly continues to work. (#70)
- `check_returns_exact(expected_types, values, count)` and the
  `VARARG` (`'...'`) marker in `llx.check_arguments`, reusable outside
  the `Signature` wrapper.
- `Callable(params, returns, opts)` matcher: the runtime analog of
  Python's `Callable[[A, B], R]`. Signature-wrapped functions are
  matched against their declared types with the standard variance
  rules (parameters contravariant, returns covariant); raw functions
  fall back to arity checking, lenient by default and exact with
  `{strict = true}`. (#25)
- `is_subtype(a, b)` and `signature_compatible(sub, super)` in the
  new `llx.is_subtype` module, both flattened to the root: the
  type-level subtype relation (reflexivity, `Any` as top type,
  numeric widening, union member/whole rules, and transitive class
  inheritance) and the function-signature variance relation built on
  it. (#26)
- `Tuple` matcher for fixed-shape positional tables, the runtime
  analog of `tuple[A, B]`. Reachable via
  `require('llx.types.matchers').Tuple` only: the root-level
  `llx.Tuple` name is owned by the value class. (#27)
- `ListOf(T)` and `SetOf(T)` matchers for homogeneous `llx.List` (or
  list-shaped table) and `llx.Set` contents. (#28)
- `Literal{...}` matcher accepting an explicit list of scalar values
  (strings, numbers, booleans), the runtime analog of
  `typing.Literal`. (#29)
- `Never` matcher: the bottom type that matches no value, useful as
  an explicit "unreachable" annotation and as the identity for
  `Union`. (#30)
- `Protocol` optional fields and closed shapes: wrap a field type in
  `Optional(T)` to make the key optional, and set `__exact = true`
  to reject keys not named in the shape (TypedDict-style). (#31)
- `NewType(name, base)` branded types, the runtime analog of Python's
  `NewType`: the constructor validates against the base type and
  brands the value; brands are distinct from each other and from the
  raw base, while `is_subtype(Brand, base)` still holds. Wrappers
  forward operators to the underlying value; unwrap with `:get()`.
  (#32)
- `cast(value, T)` and `try_cast(value, T)` checked casts in the new
  `llx.cast` module, flattened to the root: `cast` returns the value
  unchanged or raises `TypeError`; `try_cast` returns
  `Ok(value)`/`Err(TypeError)` via `llx.result`. (#33)
- `TypeVar(name, opts)` generic type variables with per-call,
  first-witness binding inside `Signature`/`Overload`-checked calls;
  `opts.bound` constrains admissible values. Outside a checked call a
  TypeVar matches anything satisfying its bound. (#49)
- `ClassOf(C)` matcher for class objects themselves (the runtime
  analog of `type[C]`): matches `C` or any transitive subclass, never
  an instance; `ClassOf()` matches any class. (#50)
- `Rest(T)` markers and variadic `Tuple` shapes: `Tuple{A, Rest(T)}`
  types a homogeneous checked tail (the analog of `tuple[T, ...]`),
  and a trailing `'...'` declares an unchecked tail, mirroring the
  signature convention. (#51)
- `Overload{...}`: an ordered overload set of signature-bound
  functions with first-match-wins dispatch, the runtime analog of
  `@overload`. Built on the new binding operator
  `Signature{...} .. fn`, which wraps a function outside the
  class-decorator syntax. When no candidate accepts a call, the new
  `OverloadResolutionException` (an `ExceptionGroup`) lists every
  candidate with its rejection reason. `Callable` and
  `signature_compatible` treat an overload set as compatible when any
  declaration is. (#53)
- `Lazy(thunk)` matcher for recursive and forward type references:
  the thunk resolves on first use and the result is cached;
  self-referential resolution chains raise instead of overflowing the
  stack. `resolve_lazy(matcher)` forces one explicitly, `is_subtype`
  sees through Lazy, and `Schema` `type` fields accept Lazy matchers
  so schemas can be recursive. (#54)
- Typed iterators and coroutine generators: `Iterator(T, ...)` and
  `Generator{yields=, accepts=, returns=}` matchers (the runtime
  analogs of `Iterator[T]` and `Generator[Y, S, R]`), plus the new
  `llx.typed_iterators` module whose `Yields{...} .. fn` and
  `Generates{...} .. body` wrappers opt in to per-step boundary
  checking of yields, sends, and returns. The generator variance
  relation `generator_compatible(sub, super)` (yields/returns
  covariant, accepts contravariant) is exported from
  `llx.is_subtype`. (#55)

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

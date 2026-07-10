# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `TypeVarTuple('Ts')` (exported as `llx.TypeVarTuple`, with the
  `llx.is_type_var_tuple` predicate) and its splice marker
  `Unpack(Ts)` (exported as `llx.Unpack`, with `llx.is_unpack`): a
  variadic type variable, the runtime analog of Python's
  `typing.TypeVarTuple`. Where a `TypeVar` binds one type a
  `TypeVarTuple` binds a *sequence*, spliced into a list through
  `Unpack(Ts)`, so a `Tuple` or signature generic over arity can be
  declared -- `Tuple{Unpack(Ts)}` is a tuple of any shape,
  `Callable({Unpack(Ts)}, {Tuple{Unpack(Ts)}})` an args-packing
  helper. An `Unpack` is legal only as a list entry (`Tuple` elements,
  `Callable` params or returns); at most one per list, and never
  combined with a trailing `VARARG`/`Rest(T)` tail (a fixed prefix and
  suffix may surround it). At the value level a spliced `Tuple` checks
  its fixed prefix and suffix and leaves the middle run free
  (unconstrained arity). At the type level `signature_compatible` (and
  therefore `Callable`/`is_subtype`) unifies a candidate-side `Unpack`
  by the `ParamSpec` rules one level down -- against a sub-sequence
  instead of a whole list: the first occurrence captures the
  counterpart's spanned region verbatim (an empty span binds `Ts` to
  the empty sequence) and later occurrences substitute it, so a
  `params`/`returns` pair correlates through `Ts`. Only the candidate
  side unifies; a super-side (or shared) `Unpack` stays universal.
  Capturing from a variadic (`Rest`/`VARARG`) counterpart region is
  refused (no finite sequence to bind). This first iteration is
  type-level only, like `ParamSpec`: an `Unpack` carries information
  for the `is_subtype`/`signature_compatible` relation over declared
  types and has no call-time meaning, so `Signature`/`Function` reject
  it (and a bare `TypeVarTuple`), and a `Callable` with an `Unpack`
  parameter list treats parameters as unchecked for raw functions.
  Length arithmetic over sequences, multiple `Unpack`s per list, and
  `Unpack` inside `Dict`/`SetOf` are deliberately out of scope. (#104)
- `ParamSpec('P')` (exported as `llx.ParamSpec`, with the
  `llx.is_param_spec` predicate): a parameter-list variable, the
  runtime analog of Python's `typing.ParamSpec`. Like `AnyParams` it
  stands *in place of* a `Callable`'s whole parameter list --
  `Callable(P, {R})` -- but captures the list instead of erasing it,
  so forwarding wrappers (decorators, tracing/memoization
  combinators) that preserve a wrapped function's parameters can be
  typed. `signature_compatible` (and therefore the `Callable` matcher
  and `is_subtype`) unifies a candidate-side ParamSpec by exactly the
  `TypeVar` rules one level up -- against a whole parameter list
  instead of a single type: the first occurrence captures the
  counterpart's entire list (including its trailing VARARG tail or
  `AnyParams`-ness, verbatim) and later occurrences substitute it, so
  the canonical decorator shape
  `Callable({Callable(P, {T})}, {Callable(P, {T})})` is compatible
  with a concrete
  `Callable({Callable({Integer}, {String})}, {Callable({Integer},
  {String})})`. Only the candidate side's ParamSpec unifies; a
  super-side (or shared) one stays universal, so a concrete wrapper
  is never compatible with a generic one. This first iteration is
  type-level only: a ParamSpec carries information for the
  `is_subtype`/`signature_compatible` relation over declared types
  and has no call-time meaning, so `Signature`/`Function` reject it
  (as a field or an entry), and at the value level a `Callable(P, R)`
  treats parameters as unchecked for raw functions, exactly as
  `AnyParams` does. `strict` is rejected with a ParamSpec (no
  declared shape to enforce), and a ParamSpec is rejected as a list
  *entry* everywhere `AnyParams` is (it replaces the whole list).
  Concatenate-style leading fixed parameters, `P.args`/`P.kwargs`
  projection, and value-level participation are deliberately out of
  scope for this iteration; the captured-list boundary is the
  composition point for a future `TypeVarTuple`/`Unpack` analog
  (#104). (#103)

### Changed

- `is_subtype` now compares parameterized matchers of the same kind
  structurally instead of by spelled name, extending the #73 Tuple
  work to the remaining containers. `ListOf` and `SetOf` elements
  are covariant (`ListOf(Integer)` is now a subtype of
  `ListOf(Number)`); `Dict` values are covariant while keys are
  invariant -- a key type occupies both an output position
  (iteration yields keys) and an input position (lookups take a
  key), so neither widening direction is sound, the same rule mypy
  applies to `Mapping`'s key parameter; two unions always compare
  member-wise; and two `Callable` matchers compare by
  `signature_compatible` (so `Callable({Integer}, {R})` is now a
  subtype of `Callable(AnyParams, {R})`), except that a lenient
  Callable is never a subtype of a strict one (strict narrows which
  raw functions the matcher accepts at the value level) and a
  Callable declaring AnyParams is a subtype only of another
  AnyParams Callable (its value set spans every parameter shape;
  `signature_compatible`'s AnyParams-as-sub direction is documented
  as gradual, not sound). Structural verdicts are final -- these
  pairs never fall back to name equality -- so distinct same-named
  classes (and TypeVars) are no longer conflated one wrapper up inside
  `Union{C}`, `ListOf(C)`, `SetOf(C)`, `Dict(K, V)`, or Callable
  parameter/return lists. Matchers without a structural rule
  (`Iterator`, `Generator`, `Protocol`, `NewType`, `ClassOf`) still
  compare by name. As with Tuples, structurally comparing two
  *separately constructed* recursive containers is self-dependent
  and now raises the cyclic-comparison error (previously the unique
  Lazy placeholder names made such comparisons return false);
  compare recursive types by identity (the same matcher object on
  both sides). (#94)
- `isinstance` against a degenerate self-referential union -- one
  whose member walk reaches the same union with the same value
  again, e.g. `local A; A = Union{Lazy(function() return A end)}`
  -- now raises a clear "cyclic type check" error instead of
  recursing without bound (previously a stack overflow at check
  time). The guard is pair-based, mirroring the occurs check
  `is_subtype` gained in #73: recursion that descends into *parts*
  of the value (JSON-style recursive unions over `ListOf`/`Dict`
  members) checks different values against the union and is
  unaffected, while a value that contains itself exactly where the
  type recurses is genuinely self-dependent and raises too. (#94)

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
- **Breaking:** `llx.signature.Function` now requires a callable
  `func` at construction and raises a typed
  `InvalidArgumentException` when it is missing or not callable.
  Previously `Function{params={}, returns={}}` constructed fine and
  crashed at call time as a raw "attempt to call a nil value" inside
  `__call`, far from the mistake. `Signature` is unchanged: it
  declares types only and binds the callable later (via `decorate`
  or the `..` operator). (#93)
- **Breaking:** the composite matcher constructors -- `Union`,
  `Optional` (both calling forms), `Dict`, `ListOf`, `SetOf`, and
  `Protocol` field types -- now reject stray `Rest(T)` and
  `AnyParams` markers at construction with a typed `ValueException`,
  through the same shared helper (and with the same messages) as the
  existing `Callable`/`Iterator`/`Generator`/`Signature` list
  validation. Neither marker carries `__isinstance`, so such a
  position was silently unsatisfiable -- and `Optional(Rest(T))` was
  worse: the marker was mistaken for the list-wrapped calling form
  and the matcher silently collapsed to `Union{Nil, nil}`, satisfied
  only by nil. Markers in their valid positions (`Rest(T)` trailing
  a `Tuple` element list, `AnyParams` in place of `Callable`'s
  parameter list) are unaffected, including nested inside
  composites. (#93)
- **Breaking:** `Generator{...}` now validates VARARG placement: a
  non-trailing `'...'` in the `yields`, `accepts`, or `returns`
  contract list raises a typed `ValueException` at construction.
  `generator_compatible` treats only a *trailing* `'...'` as the
  variadic tail, so such a contract was silently incompatible with
  every declared generator while the structural thread fallback
  still accepted every coroutine -- the same gap `Callable` and
  `Iterator` already close for their lists. (#93)
- The remaining plain-string marker placement errors now raise typed
  `ValueException`s with unchanged message text, matching the
  `Rest`/`AnyParams` rejections: `Callable`'s non-trailing-VARARG
  errors (parameter and return lists) and its AnyParams-as-return-
  list error, `Iterator`'s non-trailing-VARARG error, and `Tuple`'s
  non-final `'...'`/`Rest(T)` error. Code that matched these
  messages with string operations should match on the exception's
  `.what` instead. (#93)

### Fixed

- A malformed catch type in the try/catch DSL no longer masks the
  exception being handled. Since #67 made `isinstance` raise on
  non-matcher type arguments, a catch clause whose type was not a
  class or matcher (previously it just silently never matched)
  raised `InvalidArgumentException` from inside the unwind path,
  replacing the user's original exception with a confusing secondary
  one. Catch dispatch now treats a clause whose type is neither a
  string nor a matcher (a table with a callable `__isinstance`) --
  and any non-table clause entry -- as non-matching, so the original
  exception reaches later catchers or propagates unchanged.
  `catch()` itself now rejects such types up front (see Added), so
  only hand-built clause tables can reach this backstop. (#92)
- `check_arguments` now raises a well-formed
  `InvalidArgumentException` when a checked function's parameter has
  no entry in the declared `{name = type}` table, reporting the
  parameter's index, name, and actual type (e.g. `parameter 'b' has
  no declared type (got Number)`). The undeclared-parameter branch
  previously called the exception constructor with the wrong arity,
  so hitting it raised an arithmetic error on a class table instead
  of a diagnostic. (#91)
- The unit framework's `expect(fn).to_not.throw(expected)` no longer
  silently ignores its expected-message argument. It previously
  negated only the did-it-throw boolean, so any thrown error failed
  the assertion and the message was never compared, making
  message-specific negative assertions impossible to express. It now
  means "does not throw an error equal to `expected`": not throwing
  passes, throwing a different error passes, and throwing that exact
  error fails. String messages are compared after stripping the
  leading `file:line:` position prefix (sharing #66's stripping
  logic); non-string errors compare by raw equality. Bare
  `to_not.throw()` still fails on any error. (#90)
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

- TypeVar constraint solving in `signature_compatible` (and
  therefore in the `Callable` matcher and the structural Callable
  rule of `is_subtype`): the candidate signature's type variables now
  unify against their concrete counterparts instead of excluding the
  whole signature from the relation. Within one declared comparison,
  a variable's first occurrence (parameters left to right, then
  returns) instantiates it, every later occurrence resolves to that
  instantiation and is checked with its own position's variance, and
  a declared `bound` is respected at instantiation
  (`is_subtype(binding, bound)`, conservative for structural
  bounds). A generic signature such as
  `{params = {ListOf(T)}, returns = {T}}` is now compatible with
  `Callable({ListOf(Integer)}, {Integer})`, and
  `isinstance(wrapped_generic_fn, concrete_callable)` accepts.
  Deliberate design decisions, documented on
  `signature_compatible`: the relation reads the variable as
  universally quantified over the outermost declared signature pair
  (mypy's whole-signature reading of a generic callable), so only
  the *candidate* side's variables instantiate -- a concrete
  signature is still never compatible with a generic super (super's
  variables promise every binding), even where a contravariant
  parameter position nests super's generic Callable as the inner
  candidate -- while alpha-equivalent generic signatures now relate
  (a candidate variable may instantiate to a universal one
  pointwise). A variable occurring on *both* sides never
  instantiates (unifying it would let super's universal promise
  capture the candidate's instantiation; compare signatures renamed
  apart where that matters), which also keeps self-referential
  shared-variable corners a deterministic false, backstopped by an
  occurs check. Nested Callables share the enclosing comparison's
  instantiations, and `generator_compatible` spans its whole
  yields/accepts/returns contract with a single instantiation; each
  declaration of a top-level Overload is a separate comparison with
  its own (so a generic candidate may instantiate differently per
  overloaded-super declaration); speculative branches (union
  members, overload alternatives, superclass walks) roll failed
  instantiations back; and solving is greedy (first occurrence
  fixes the instantiation -- sound but incomplete relative to a
  full constraint solver). Plain `is_subtype` outside a signature
  comparison, and the value-level first-witness runtime binding,
  are unchanged; where the runtime witness protocol is narrower
  than the declared reading (narrow first-witness inference,
  unwitnessed variables), the relation follows the declared
  reading, as documented. First item of the generics follow-up
  umbrella. (#96)
- `Generator{..., strict = true}`: a strict mode for the `Generator`
  matcher, following the `Iterator` precedent from #74. By default a
  bare coroutine thread matches any `Generator` contract structurally
  (a raw thread carries no contract, so nothing about its yields,
  sends, or returns can be verified -- the documented weak fallback);
  with `strict = true` that fallback is disabled entirely, so only
  values that declare their contract (`Generates{...}`-wrapped
  generators, i.e. `GeneratorInstance` values) can match, compared
  with the variance rules of lenient mode unchanged (yields and
  returns covariant, accepts contravariant). Plain functions and
  `coroutine.wrap` results remain rejected in both modes. The flag
  lives *inside* the contract table rather than in a trailing second
  argument: `Generator`'s calling form is already a single named-key
  table (`Iterator` needed a trailing options table only because its
  yields are positional varargs), and the contract keys are a fixed
  reserved set, so `strict` cannot collide with anything. Strictness
  is part of the matcher's name
  (`Generator<yields=(T), accepts=(), returns=()> strict`), which is
  what keeps the strict and lenient forms distinct in `is_subtype`'s
  name fallback. A non-boolean `strict` raises at construction, the
  same policy `Iterator` applies. (#95)
- String catchers in the try/catch DSL: `catch('TypeError',
  handler)` now matches any thrown value whose class -- or any
  superclass, walked transitively -- has that `__name`. This extends
  the library's string type names (as accepted by `Signature`
  params) to catch clauses, with one deliberate difference: catchers
  walk the superclass chain, where `Signature`'s string matching is
  exact-name only, because catching a base class is expected to
  catch derived ones. Clauses are still checked in order with the
  first match winning, and string and class/matcher catchers mix
  freely in one `try` block. Dispatch goes through `getclass`, so
  string catchers also see non-exception errors: `catch('String',
  h)` catches raw `error('msg')` strings. As with string type names
  elsewhere in the library, matching is by name only, so distinct
  classes sharing a `__name` are conflated; catch by the class
  object where identity matters. `catch()` now also validates its
  type argument at construction: anything that is neither a string
  nor a class/matcher with a callable `__isinstance` (e.g. a number,
  `nil`, or a plain table) raises `InvalidArgumentException` at the
  `catch()` call site instead of sitting in the clause list silently
  unmatched. (#92)
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

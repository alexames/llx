-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

-- Subtype relation between type matchers, and the signature
-- compatibility relation built on top of it.
--
-- `is_subtype(a, b)` answers whether a value of type `a` can safely be
-- used where a value of type `b` is expected. `signature_compatible`
-- applies the standard variance rules to two declared signatures:
-- parameters are contravariant, return values are covariant.
--
-- Fundamental runtime limitation: raw Lua functions carry no type
-- information, so these relations can only compare *declared* types
-- (class tables, type matchers, Signature wrappers, or Callable
-- matchers), never arbitrary runtime functions.

local check_arguments = require 'llx.check_arguments'
local environment = require 'llx.environment'
local matchers = require 'llx.types.matchers'

local Float = require 'llx.types.float' . Float
local Integer = require 'llx.types.integer' . Integer
local Number = require 'llx.types.number' . Number

local Any = matchers.Any
local Never = matchers.Never
local VARARG = check_arguments.VARARG
local is_any_params = matchers.is_any_params
local is_type_var = matchers.is_type_var
local resolve_lazy = matchers.resolve_lazy

local _ENV, _M = environment.create_module_environment()

local anonymous_class_name = '<anonymous class>'

-- Equality between two type matchers, mirroring the rules used for
-- signature matching: identical objects, a class proxy against its
-- internal table (via the class system's __eq), two matchers exposing
-- the same non-anonymous __name (so separately constructed matchers
-- such as Dict(String, Integer) compare equal), or a string type name
-- (Signature declarations may name a type by string, as supported by
-- check_arguments) against the other side's __name. Anonymous classes
-- share a placeholder __name, so they only ever match by identity.
--
-- llx classes carry identity (their __is_llx_class marker), so the
-- table-to-table name fallback never applies when either side is a
-- class: two distinct classes that happen to share a __name are
-- distinct types, not mutual subtypes. Parameterized matchers
-- (Dict(String, Integer) and friends) have no identity -- separately
-- constructed instances are meant to compare equal -- so they keep
-- the name rule, as do string type names (a bare string cannot carry
-- identity at all, so it matches classes and matchers by name alike).
local function type_equal(a, b)
  if rawequal(a, b) then return true end
  local a_type, b_type = type(a), type(b)
  if a_type == 'string' and b_type == 'string' then
    return a == b
  end
  if a_type == 'string' and b_type == 'table' then
    return a == b.__name
  end
  if b_type == 'string' and a_type == 'table' then
    return b == a.__name
  end
  if a_type == 'table' and b_type == 'table' then
    -- == sees through the class system's proxy/internal-table split
    -- (a class proxy's __eq compares underlying class identity).
    if a == b then return true end
    if a.__is_llx_class or b.__is_llx_class then
      return false
    end
    local a_name = a.__name
    return a_name ~= nil
       and a_name ~= anonymous_class_name
       and a_name == b.__name
  end
  return false
end

-- Union matchers (and matchers built on them, such as Optional)
-- expose their member list as a `type_list` field. rawget keeps class
-- proxies and inherited fields from producing false positives.
local function union_members(t)
  if type(t) == 'table' then
    return rawget(t, 'type_list')
  end
  return nil
end

-- Overload sets (llx.signature.Overload) expose their declaration
-- list as an `overloads` field on the instance; each member is a
-- Signature-wrapped Function carrying `params`/`returns`. rawget
-- keeps class proxies and inherited fields from producing false
-- positives.
local function overload_members(t)
  if type(t) == 'table' then
    return rawget(t, 'overloads')
  end
  return nil
end

-- Tuple matchers (llx.types.matchers.Tuple) expose their derived
-- shape -- element_types, fixed_count, variadic, rest_type -- for
-- exactly this kind of structural introspection. rawget keeps class
-- proxies and inherited fields from producing false positives.
local function is_tuple(t)
  return type(t) == 'table'
     and rawget(t, 'element_types') ~= nil
     and rawget(t, 'fixed_count') ~= nil
end

-- Forward declaration: the recursion below must thread the
-- cycle-guard bookkeeping through every nested comparison.
local is_subtype_impl

-- Structural subtyping between two Tuple matchers. Elements compare
-- covariantly: a tuple is a positional value container, so a tuple
-- of narrower elements can stand in wherever a tuple of wider ones
-- is expected. The arity rules mirror the return-list rules of
-- signature_compatible (a tuple type, like a return list, describes
-- values its holder observes):
--
-- - Fixed `b`: `a` must be fixed with the same arity. A variadic `a`
--   also admits longer values, which `b`'s holder would observe.
-- - Variadic `b`: `a`'s minimum length (its fixed prefix) must cover
--   `b`'s fixed prefix, `a` positions beyond that prefix must
--   satisfy `b`'s tail, and a variadic `a`'s tail must too. The
--   unchecked '...' tail admits any value, so it behaves as a tail
--   of Any on both sides: every element type satisfies an unchecked
--   `b` tail, while an unchecked `a` tail satisfies only a `b` tail
--   that admits Any.
local function tuple_subtype(a, b, in_progress)
  local a_fixed = rawget(a, 'fixed_count')
  local b_fixed = rawget(b, 'fixed_count')
  local a_variadic = rawget(a, 'variadic')
  if rawget(b, 'variadic') then
    if a_fixed < b_fixed then
      return false
    end
  elseif a_variadic or a_fixed ~= b_fixed then
    return false
  end
  local a_types = rawget(a, 'element_types')
  local b_types = rawget(b, 'element_types')
  local b_tail = rawget(b, 'rest_type') or Any
  for i = 1, a_fixed do
    local expected = i <= b_fixed and b_types[i] or b_tail
    if not is_subtype_impl(a_types[i], expected, in_progress) then
      return false
    end
  end
  if a_variadic then
    local a_tail = rawget(a, 'rest_type') or Any
    if not is_subtype_impl(a_tail, b_tail, in_progress) then
      return false
    end
  end
  return true
end

-- The relation proper, applied to resolved operands. is_subtype_impl
-- wraps it with Lazy resolution and the cycle-guard bookkeeping;
-- the public is_subtype below documents the rules.
local function subtype_rules(a, b, in_progress)
  -- TypeVars (llx.types.matchers.TypeVar) are excluded from the
  -- variance relation in this first iteration: a type variable stands
  -- for a per-call binding, not a concrete type, so without a
  -- constraint solver the only sound relations are identity (a
  -- variable is trivially a subtype of itself) and widening to the
  -- top type (every binding is a subtype of Any). Everything else --
  -- including is_subtype(T, T.bound), which the value-level bound
  -- check does not justify for structural bounds, and
  -- is_subtype(Never, T) for a TypeVar T -- is conservatively
  -- false. Checked before the name-equality rule below so two
  -- distinct TypeVars sharing a name are never conflated.
  if is_type_var(a) or is_type_var(b) then
    return rawequal(a, b) or rawequal(b, Any)
  end
  -- Never is the bottom type: no value of type Never can exist, so
  -- Never can stand in for every type. In the other direction
  -- nothing but Never itself is a subtype of Never -- except an
  -- uninhabited union, which the union rule below accepts vacuously
  -- (an empty union, or a union of Nevers, promises no inhabitants
  -- either).
  if rawequal(a, Never) then
    return true
  end
  -- Tuples compare structurally when both sides are Tuple matchers,
  -- taking precedence over the name fallback: names freeze Lazy
  -- placeholders and conflate distinct element types that share a
  -- name, so the structural verdict -- either way -- is final.
  -- rawequal keeps the relation reflexive for recursive tuples
  -- without a self-dependent element walk.
  if is_tuple(a) and is_tuple(b) then
    return rawequal(a, b) or tuple_subtype(a, b, in_progress)
  end
  if type_equal(a, b) then
    return true
  end
  -- Any is the top type.
  if rawequal(b, Any) then
    return true
  end
  -- A union is a subtype of b when every member is. An empty union
  -- is vacuously a subtype of everything (it is an uninhabited,
  -- Never-like type).
  local a_members = union_members(a)
  if a_members then
    for _, member in ipairs(a_members) do
      if not is_subtype_impl(member, b, in_progress) then
        return false
      end
    end
    return true
  end
  -- a is a subtype of a union when it is a subtype of any member.
  local b_members = union_members(b)
  if b_members then
    for _, member in ipairs(b_members) do
      if is_subtype_impl(a, member, in_progress) then
        return true
      end
    end
    return false
  end
  -- Numeric widening. Only the matcher tables participate; string
  -- type names compare by name equality alone.
  if rawequal(b, Number)
      and (rawequal(a, Integer) or rawequal(a, Float)) then
    return true
  end
  -- Classes: walk the superclass chain transitively.
  if type(a) == 'table' then
    local superclasses = a.__superclasses
    if superclasses then
      for _, superclass in ipairs(superclasses) do
        if is_subtype_impl(superclass, b, in_progress) then
          return true
        end
      end
    end
  end
  return false
end

function is_subtype_impl(a, b, in_progress)
  if a == nil or b == nil then
    return false
  end
  -- Lazy matchers are forced up front (llx.types.matchers.Lazy;
  -- forcing caches the resolution), so the whole relation -- name
  -- equality, union member walks, numeric widening, superclass
  -- chains -- sees the resolved matchers. Nested Lazy members are
  -- forced by the recursive comparisons below.
  a = resolve_lazy(a)
  b = resolve_lazy(b)
  if type(a) ~= 'table' or type(b) ~= 'table' then
    return subtype_rules(a, b, in_progress)
  end
  -- Cycle guard: a type that contains itself as a direct member
  -- through Lazy (e.g. a Lazy union containing only itself) can
  -- make a comparison depend on its own outcome. Re-entering a
  -- comparison that is
  -- already in progress can never produce new information, so it
  -- raises a clear error instead of recursing without bound. The
  -- bookkeeping table is created per top-level call and pairs are
  -- unmarked on the way out, so only true self-dependence trips the
  -- guard (shared subterms compared twice on different paths do
  -- not), and an error propagating out of a nested rule (a failing
  -- Lazy thunk, say) cannot leak marks into later calls.
  local seen = in_progress[a]
  if seen == nil then
    seen = {}
    in_progress[a] = seen
  elseif seen[b] then
    error('is_subtype: cyclic type comparison: deciding whether '
      .. tostring(a) .. ' is a subtype of ' .. tostring(b)
      .. ' depends on itself (a recursive type that contains '
      .. 'itself as a direct member?)', 0)
  end
  seen[b] = true
  local result = subtype_rules(a, b, in_progress)
  seen[b] = nil
  return result
end

--- Returns true when type `a` is a subtype of type `b`.
--
-- A value of type `a` can safely be used wherever a value of type `b`
-- is expected. The relation is reflexive and covers:
--
-- - `Any` as the top type: everything is a subtype of `Any`.
-- - `Never` as the bottom type: `Never` is a subtype of everything,
--   and nothing but `Never` itself (and an uninhabited union, which
--   the union rule accepts vacuously) is a subtype of `Never`.
-- - `Union`: a union is a subtype of `b` when every member is; `a` is
--   a subtype of a union when it is a subtype of any member.
-- - Numeric widening: `Integer` and `Float` are subtypes of `Number`,
--   mirroring the value level where both satisfy `Number`.
-- - Classes: the transitive `__superclasses` chain is walked, so a
--   derived class is a subtype of each of its bases.
-- - `Tuple`: two Tuple matchers compare structurally, element-wise
--   covariantly, with fixed/variadic arity rules mirroring the
--   return-list rules of `signature_compatible` (see tuple_subtype
--   above). The structural verdict is final: two Tuples never fall
--   back to name equality.
-- - `Lazy`: deferred references are forced (resolving and caching
--   the underlying matcher) before comparison, so a Lazy compares
--   exactly as the matcher it resolves to.
-- - `TypeVar`: a type variable is a subtype only of itself and of
--   `Any`; every other comparison involving a TypeVar is false.
--   Generic signatures are thereby conservatively excluded from
--   `signature_compatible` in this iteration (see the matcher's
--   documentation in llx.types.matchers).
--
-- Caveats: distinct *matchers* sharing a non-anonymous `__name`
-- compare as equal (and therefore as mutual subtypes) -- by design,
-- so separately constructed parameterized matchers such as
-- Dict(String, Integer) compare equal. llx classes carry identity,
-- so the name fallback never applies when either side is a class:
-- two distinct classes sharing a `__name` are unrelated. A container
-- matcher's name embeds only its element types' *names*, though, so
-- same-named classes are still conflated one level up inside
-- non-Tuple containers (Union{C}, ListOf(C), ...), whose comparison
-- remains name-based. String type names participate in name equality
-- only -- a string cannot be resolved to a type, so it gets neither
-- the class-hierarchy walk nor numeric widening on the subtype side.
--
-- A comparison whose outcome depends on itself raises an error
-- instead of recursing without bound. That happens when a type
-- contains itself as a direct member through Lazy (e.g. a Lazy
-- union containing only itself) and the comparison reaches that
-- member; every such comparison previously overflowed the stack.
-- Recursion routed through a container matcher -- a leaf of this
-- relation -- never re-enters, so JSON-style recursive unions are
-- unaffected. Compare separately constructed recursive types by
-- identity (the same matcher object on both sides) rather than by
-- structure.
--
-- @param a The candidate subtype (a type matcher, class, or name)
-- @param b The candidate supertype (a type matcher, class, or name)
-- @return True if `a` is a subtype of `b`, otherwise false
function is_subtype(a, b)
  return is_subtype_impl(a, b, {})
end

-- Splits a declared type list into its fixed (typed) prefix length
-- and a variadic flag. Only a *trailing* VARARG ('...') entry marks
-- the list as variadic, mirroring the call-time semantics of
-- llx.check_arguments.check_returns_exact (the fixed prefix is
-- checked, any number of extra values is allowed unchecked). A
-- VARARG anywhere else is malformed -- check_returns_exact raises
-- for it at call time -- so nil is returned and the caller treats
-- the signature as incompatible with everything.
local function split_variadic(types)
  local count = #types
  local variadic = types[count] == VARARG
  local fixed_count = variadic and count - 1 or count
  for i = 1, fixed_count do
    if types[i] == VARARG then
      return nil
    end
  end
  return fixed_count, variadic
end

--- Returns true when signature `sub` can be used where `super` is
--- expected.
--
-- Both arguments are tables carrying `params` and `returns` arrays of
-- type matchers -- Signature-wrapped functions, Callable matchers, or
-- plain `{params = {...}, returns = {...}}` tables. Missing lists
-- default to empty. A trailing VARARG (`'...'`) entry in either list
-- declares a variadic tail: the fixed prefix is typed and anything
-- beyond it is unchecked at call time (see llx.check_arguments).
--
-- Variance rules (the relation mypy applies to Callable):
--
-- - Parameters are contravariant: each parameter type `super`
--   promises must be a subtype of the `sub` parameter type checked at
--   that position, so `sub` accepts at least everything `super`
--   promises to accept.
-- - Returns are covariant: each return type `super` promises must be
--   met by a `sub` return type that is a subtype of it.
--
-- Arity, fixed lists: parameter and return counts must match exactly.
-- For returns this is required for soundness: a Lua call in the tail
-- of an expression list expands all of its results, so extra return
-- values are observable at call sites.
--
-- Arity, variadic lists (derived from the call-time semantics, where
-- the variadic tail is unchecked):
--
-- - Variadic `sub` params: compatible when `sub`'s fixed prefix does
--   not extend past `super`'s parameter list -- every position `sub`
--   checks is one `super` promises (contravariantly), and the rest
--   land in `sub`'s unchecked tail.
-- - Fixed `sub` params under a variadic `super`: incompatible.
--   `super` promises callers may pass arbitrary extra arguments,
--   which `sub`'s call-time count check rejects.
-- - Variadic `sub` returns under a fixed `super`: incompatible.
--   `sub` may produce extra results beyond its fixed prefix, and
--   callers of `super` would observe those undeclared extras.
-- - Fixed `sub` returns under a variadic `super`: compatible when
--   `sub`'s returns cover `super`'s fixed prefix (covariantly);
--   further `sub` returns land in `super`'s unchecked tail.
--
-- Note that a variadic `super` parameter list is not an "any
-- parameters" wildcard (mypy's `Callable[..., R]`): it is a promise
-- that callers may pass arbitrary extras, so only a variadic `sub`
-- satisfies it. The wildcard is spelled with the AnyParams sentinel
-- (llx.types.matchers.AnyParams) *in place of* a parameter list, as
-- Callable(AnyParams, {R}) exposes it: a side declaring AnyParams
-- does not constrain parameters at all, so when either side declares
-- it the parameter checks are skipped and only returns are compared.
-- A `sub` with AnyParams accepts every parameter list, which is
-- sound against any `super`; an AnyParams `super` accepting a fixed
-- `sub` is, like Any, deliberately gradual rather than sound (a
-- caller holding the `super` view may pass arguments `sub` never
-- declared). AnyParams is params-only: in a return position the
-- contract is malformed and compatible with nothing, the same
-- policy as a non-trailing VARARG.
--
-- A non-trailing VARARG makes a signature malformed (its call-time
-- check raises unconditionally), so it is compatible with nothing.
--
-- Overload sets (llx.signature.Overload, recognized by their
-- `overloads` declaration list) participate with intersection-type
-- semantics, mirroring mypy's treatment of @overload:
--
-- - An overloaded `sub` is compatible with `super` when *any* of its
--   declarations is: a caller holding the `super` view picks one
--   compatible declaration and the set dispatches at least as
--   broadly.
-- - An overloaded `super` requires `sub` to be compatible with
--   *every* declaration: `super` promises all of them, so `sub` must
--   honor each. (Checked first, so an overloaded `sub` must cover
--   each `super` declaration with some -- not necessarily the same --
--   declaration of its own.)
--
-- @param sub The candidate signature (used where `super` is expected)
-- @param super The required signature
-- @return True if `sub` is compatible with `super`, otherwise false
function signature_compatible(sub, super)
  if type(sub) ~= 'table' or type(super) ~= 'table' then
    return false
  end
  local super_overloads = overload_members(super)
  if super_overloads then
    for _, declaration in ipairs(super_overloads) do
      if not signature_compatible(sub, declaration) then
        return false
      end
    end
    return true
  end
  local sub_overloads = overload_members(sub)
  if sub_overloads then
    for _, declaration in ipairs(sub_overloads) do
      if signature_compatible(declaration, super) then
        return true
      end
    end
    return false
  end
  local sub_params = sub.params or {}
  local super_params = super.params or {}
  local sub_returns = sub.returns or {}
  local super_returns = super.returns or {}
  -- AnyParams is only meaningful in place of a *parameter* list; a
  -- return list "declared" as AnyParams is malformed, so it is
  -- compatible with nothing (Callable rejects the spelling at
  -- construction; this guards plain contract tables).
  if is_any_params(sub_returns) or is_any_params(super_returns) then
    return false
  end
  local params_any =
      is_any_params(sub_params) or is_any_params(super_params)
  local sub_params_fixed, sub_params_variadic
  if not is_any_params(sub_params) then
    sub_params_fixed, sub_params_variadic =
        split_variadic(sub_params)
    -- A malformed (non-trailing VARARG) list is compatible with
    -- nothing, even under an AnyParams counterpart: AnyParams
    -- accepts every well-formed parameter list, not broken ones.
    if sub_params_fixed == nil then
      return false
    end
  end
  local super_params_fixed, super_params_variadic
  if not is_any_params(super_params) then
    super_params_fixed, super_params_variadic =
        split_variadic(super_params)
    if super_params_fixed == nil then
      return false
    end
  end
  local sub_returns_fixed, sub_returns_variadic =
      split_variadic(sub_returns)
  local super_returns_fixed, super_returns_variadic =
      split_variadic(super_returns)
  if sub_returns_fixed == nil or super_returns_fixed == nil then
    return false
  end
  if not params_any then
    -- Parameter arity. A variadic super promises callers may pass
    -- arbitrary extra arguments, which only a variadic sub accepts
    -- at call time. A variadic sub is fine anywhere its checked
    -- prefix does not extend past super's parameter list. When
    -- either side declares AnyParams the parameter checks are
    -- skipped entirely (see the AnyParams notes above): only returns
    -- are compared.
    if super_params_variadic and not sub_params_variadic then
      return false
    end
    if sub_params_variadic then
      if sub_params_fixed > super_params_fixed then
        return false
      end
    elseif sub_params_fixed ~= super_params_fixed then
      return false
    end
  end
  -- Return arity: a variadic sub may produce undeclared extras that
  -- a fixed super's callers would observe, and a variadic super's
  -- fixed prefix must be covered by sub's declared returns.
  if sub_returns_variadic and not super_returns_variadic then
    return false
  end
  if super_returns_variadic then
    if super_returns_fixed > sub_returns_fixed then
      return false
    end
  elseif sub_returns_fixed ~= super_returns_fixed then
    return false
  end
  -- Parameters are contravariant over the positions sub checks; any
  -- super parameters beyond them land in sub's unchecked tail.
  if not params_any then
    for i = 1, sub_params_fixed do
      if not is_subtype(super_params[i], sub_params[i]) then
        return false
      end
    end
  end
  -- Returns are covariant over the positions super promises; any sub
  -- returns beyond them land in super's unchecked tail.
  for i = 1, super_returns_fixed do
    if not is_subtype(sub_returns[i], super_returns[i]) then
      return false
    end
  end
  return true
end

--- Returns true when generator contract `sub` can be used where
--- `super` is expected.
--
-- Both arguments are tables carrying `yields`, `accepts`, and
-- `returns` arrays of type matchers -- GeneratorInstance wrappers
-- (llx.typed_iterators), Generator matchers (llx.types.matchers), or
-- plain contract tables. Missing lists default to empty; a trailing
-- VARARG (`'...'`) entry declares an unchecked variadic tail, as in
-- signature declarations.
--
-- This is the generator form of the variance question raised by
-- typed coroutines, kept as a separate relation next to
-- `signature_compatible` rather than folded into it: a generator's
-- contract is three lists, not a params/returns pair, so growing
-- signature_compatible a special form would complicate its contract
-- for every existing caller. The variance rules themselves are
-- exactly the signature rules, applied twice (mirroring mypy, where
-- Generator[Y, S, R] is covariant in Y and R and contravariant in
-- S):
--
-- - yields are produced by the generator, like return values:
--   covariant.
-- - accepts (send types) are consumed by the generator, like
--   parameters: contravariant. The first resume, which starts the
--   body, does not participate (its values are not sends).
-- - returns are produced on completion: covariant.
--
-- Arity and variadic handling follow signature_compatible: yields
-- and returns get the return-list rules, accepts gets the
-- parameter-list rules, and a non-trailing VARARG makes the contract
-- compatible with nothing.
--
-- @param sub The candidate contract (used where `super` is expected)
-- @param super The required contract
-- @return True if `sub` is compatible with `super`, otherwise false
function generator_compatible(sub, super)
  if type(sub) ~= 'table' or type(super) ~= 'table' then
    return false
  end
  -- yields-out and accepts-in follow exactly a signature's
  -- returns/params variance, so reuse signature_compatible for that
  -- pair, and once more for the completion returns.
  return signature_compatible(
      {params = sub.accepts or {}, returns = sub.yields or {}},
      {params = super.accepts or {}, returns = super.yields or {}})
    and signature_compatible(
      {returns = sub.returns or {}},
      {returns = super.returns or {}})
end

return _M

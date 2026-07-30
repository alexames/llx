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
local Dynamic = matchers.Dynamic
local Never = matchers.Never
local VARARG = check_arguments.VARARG
local is_any_params = matchers.is_any_params
local is_concatenate = matchers.is_concatenate
local is_param_spec = matchers.is_param_spec
local is_rest = matchers.is_rest
local is_type_var = matchers.is_type_var
local is_unpack = matchers.is_unpack
local matcher_kind = matchers.matcher_kind
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
-- distinct types, not mutual subtypes. Parameterized matchers have
-- no identity -- separately constructed instances are meant to
-- compare equal -- so those without a structural rule in
-- subtype_rules below (Iterator, Generator, Protocol, NewType, ...)
-- keep the name rule, as do string type names (a bare string cannot
-- carry identity at all, so it matches classes and matchers by name
-- alike). Same-kind pairs of the structurally compared matchers
-- (Tuple, Union, ListOf, SetOf, Dict, Callable, GenericAlias) never
-- reach this fallback.
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

-- Forward declarations: the recursion below must thread the
-- cycle-guard bookkeeping through every nested comparison,
-- including the signature relation the Callable rule delegates to.
local is_subtype_impl
local signature_compatible_impl

-- Key under which the active TypeVar unification scope rides on the
-- in_progress bookkeeping table (a module-local sentinel, so it can
-- never collide with a matcher used as a key). The scope is opened
-- by the outermost signature pair a comparison reaches (see
-- signature_compatible_impl below) and holds:
--
-- - unifiable: the set of TypeVars declared by that pair's *sub*
--   (candidate) side, the only variables the comparison may
--   instantiate. Variables reached from the super side stay
--   universally quantified -- super promises to work for *every*
--   binding, which no single instantiation can witness -- so they
--   keep the conservative identity-only rule.
-- - bindings: TypeVar -> instantiated type, filled greedily at each
--   variable's first comparison against a counterpart.
-- - log: bind order, so speculative branches (union members,
--   overload alternatives, superclass walks) can roll back to a
--   savepoint when an alternative that recorded bindings fails.
local unify_key = {}

-- Collects every TypeVar reachable through the declared structure of
-- `t` into the set `vars`, walking the same fields the structural
-- subtype rules recurse into (union members, Tuple element lists and
-- tails, ListOf/SetOf elements, Dict keys and values, Callable
-- parameter and return lists). Matchers without a structural rule
-- (Iterator, Protocol, NewType, ...) are opaque here exactly because
-- the comparison never decomposes them, so a TypeVar inside one can
-- never surface. Lazy nodes are forced (pcall-guarded: a failing
-- thunk just leaves its variables uncollected here -- the comparison
-- that actually reaches it still raises); `seen` guards recursive
-- matchers.
-- The optional `param_specs` set, when provided, additionally
-- collects every ParamSpec standing in place of a Callable's whole
-- parameter list (Callable(P, {R})): a ParamSpec is not a list entry
-- but the `params` field itself, so it is recorded here rather than
-- reached by the entry walk. A ParamSpec never appears in a return
-- position (rejected at construction), so returns are only walked for
-- TypeVars.
-- The optional `tvts` set, when provided, collects every TypeVarTuple
-- reached through an Unpack(Ts) list entry (Tuple elements, Callable
-- params or returns): an Unpack is a list entry, so it surfaces here
-- as the entry walk descends the same lists.
local function collect_type_vars(t, vars, seen, param_specs, tvts)
  if type(t) ~= 'table' then
    return
  end
  local ok, resolved = pcall(resolve_lazy, t)
  if not ok or type(resolved) ~= 'table' then
    return
  end
  t = resolved
  if is_type_var(t) then
    vars[t] = true
    return
  end
  -- An Unpack list entry contributes its wrapped TypeVarTuple; it has
  -- no further structure to descend.
  if is_unpack(t) then
    if tvts ~= nil then
      tvts[rawget(t, 'type_var_tuple')] = true
    end
    return
  end
  if seen[t] then
    return
  end
  seen[t] = true
  local members = rawget(t, 'type_list')
  if members ~= nil then
    for _, member in ipairs(members) do
      collect_type_vars(member, vars, seen, param_specs, tvts)
    end
  end
  local elements = rawget(t, 'element_types')
  if elements ~= nil then
    for _, element in ipairs(elements) do
      collect_type_vars(element, vars, seen, param_specs, tvts)
    end
  end
  -- Generic-class alias arguments (matchers.GenericAlias): the
  -- same-kind subtype rule decomposes them per declared variance, so
  -- a TypeVar whose only occurrence is inside Pool[T] must be
  -- collected here or the signature relation would never unify it.
  local alias_args = rawget(t, 'type_args')
  if alias_args ~= nil then
    for _, alias_arg in ipairs(alias_args) do
      collect_type_vars(alias_arg, vars, seen, param_specs, tvts)
    end
  end
  collect_type_vars(rawget(t, 'rest_type'), vars, seen,
                    param_specs, tvts)
  collect_type_vars(rawget(t, 'element_type'), vars, seen,
                    param_specs, tvts)
  collect_type_vars(rawget(t, 'key_type'), vars, seen,
                    param_specs, tvts)
  collect_type_vars(rawget(t, 'value_type'), vars, seen,
                    param_specs, tvts)
  local params = rawget(t, 'params')
  if is_param_spec(params) then
    if param_specs ~= nil then
      param_specs[params] = true
    end
  elseif params ~= nil and not is_any_params(params) then
    for _, param in ipairs(params) do
      collect_type_vars(param, vars, seen, param_specs, tvts)
    end
  end
  local returns = rawget(t, 'returns')
  if returns ~= nil and not is_any_params(returns) then
    for _, entry in ipairs(returns) do
      collect_type_vars(entry, vars, seen, param_specs, tvts)
    end
  end
end

-- Collects the TypeVars of a signature-shaped value (a Signature
-- wrapper, Callable matcher, or plain contract table) into `vars`.
-- params/returns are read with plain indexing, exactly as the
-- signature relation below reads them, so Signature class instances
-- resolve their fields the same way in both places.
-- The optional `param_specs` set collects a ParamSpec standing in
-- for this signature's whole parameter list (see collect_type_vars);
-- nested ParamSpecs inside the compared matchers are collected by the
-- entry walk it threads through.
-- The optional `tvts` set collects the TypeVarTuples reached through
-- Unpack(Ts) entries in this signature's parameter and return lists
-- (and nested inside the compared matchers), the variadic-generic
-- analog of param_specs.
local function collect_signature_type_vars(sig, vars, param_specs, tvts)
  local seen = {}
  local params = sig.params
  if is_param_spec(params) then
    if param_specs ~= nil then
      param_specs[params] = true
    end
  elseif type(params) == 'table' and not is_any_params(params) then
    for _, entry in ipairs(params) do
      collect_type_vars(entry, vars, seen, param_specs, tvts)
    end
  end
  local returns = sig.returns
  if type(returns) == 'table' and not is_any_params(returns) then
    for _, entry in ipairs(returns) do
      collect_type_vars(entry, vars, seen, param_specs, tvts)
    end
  end
end

-- Instantiates the unifiable TypeVar `var` as `value` (the concrete
-- counterpart at the variable's first comparison). Returns false --
-- refusing the binding, and thereby failing the comparison that
-- needed it -- rather than record anything unsound:
--
-- - Occurs check: a binding containing the variable itself would
--   make later resolutions self-referential; refusing keeps the
--   verdict a deterministic false instead of tripping the cycle
--   guard. The apartness rule in signature_compatible_impl (a
--   variable occurring on the super side never unifies) already
--   excludes every self-occurrence the structural walk can see --
--   the walk covers exactly the fields the comparison decomposes --
--   so this is a backstop against the two ever diverging.
-- - The declared bound: instantiating T := B is only sound when
--   every value of type B satisfies the bound, i.e. is_subtype(B,
--   bound). This is conservative for structural bounds (a Protocol
--   compares by name at the type level, unlike the value-level
--   check), per the soundness-over-permissiveness policy. The
--   check runs under the active scope, so a bound containing
--   *other* unifiable variables may record bindings even when it
--   fails; that is safe for the same reason any failing conjunct
--   is -- the failure propagates to the nearest choice point,
--   whose rollback (or the scope's discard) cleans up.
local function bind_type_var(unify, var, value, in_progress)
  if type(value) == 'table' then
    local inner = {}
    collect_type_vars(value, inner, {})
    if inner[var] then
      return false
    end
  end
  local bound = rawget(var, 'bound')
  if bound ~= nil
      and not is_subtype_impl(value, bound, in_progress) then
    return false
  end
  unify.bindings[var] = value
  unify.log[#unify.log + 1] = var
  return true
end

-- ParamSpec unification (llx.types.matchers.ParamSpec): the whole-list
-- analog of TypeVar unification above, one level up. A ParamSpec
-- stands *in place of* a Callable's whole parameter list, so it is
-- unified against its counterpart's entire list rather than a single
-- type, but the rules are exactly the TypeVar rules: only a
-- candidate-side ParamSpec instantiates; a super-side (universal) one
-- keeps the identity rule.

-- Substitutes a ParamSpec that already captured a list for that list;
-- returns the value unchanged otherwise (a concrete list, AnyParams,
-- or a still-unbound ParamSpec). The captured value stands in for the
-- whole list, so the arity/variance checks then see the concrete
-- shape (including any trailing VARARG tail or AnyParams-ness the
-- capture preserved verbatim).
local function resolve_param_spec(params, unify)
  if unify ~= nil and is_param_spec(params) then
    local captured = unify.param_bindings[params]
    if captured ~= nil then
      return captured
    end
  end
  return params
end

-- Occurs check for a ParamSpec capture: refuses a capture whose
-- captured representation reaches the ParamSpec itself (directly, or
-- through a ParamSpec nested in a Callable inside the list), which
-- would make later substitutions self-referential. Like the TypeVar
-- occurs check this is a backstop -- the apartness rule (a ParamSpec
-- occurring on the super side is excluded from unification) already
-- excludes every self-occurrence the structural walk can see.
local function param_spec_occurs(ps, value)
  if rawequal(ps, value) then
    return true
  end
  if type(value) ~= 'table' or is_any_params(value) then
    return false
  end
  if is_param_spec(value) then
    return rawequal(ps, value)
  end
  local specs = {}
  for _, entry in ipairs(value) do
    collect_type_vars(entry, {}, {}, specs)
  end
  return specs[ps] == true
end

-- Instantiates the unifiable ParamSpec `ps` as `value` (its
-- counterpart's whole parameter representation -- a concrete list,
-- AnyParams, or another ParamSpec -- at the ParamSpec's first
-- comparison). Records the binding in the shared log so a speculative
-- branch can roll it back, exactly as bind_type_var does for a
-- single-type variable.
local function bind_param_spec(unify, ps, value)
  if param_spec_occurs(ps, value) then
    return false
  end
  unify.param_bindings[ps] = value
  unify.log[#unify.log + 1] = ps
  return true
end

-- Concatenate composition: when one side wraps a fixed prefix and a
-- ParamSpec, split the other side to match the prefix length and
-- compare. The prefix is contravariant (pointwise is_subtype(super, sub)),
-- and the remainder is bound to the ParamSpec. Returns true if the
-- split succeeds and the prefix matches.
local function concatenate_compatible(sub_params, super_params, in_progress)
  local unify = in_progress[unify_key]
  local sub_concat = is_concatenate(sub_params)
  local super_concat = is_concatenate(super_params)
  -- Both sides are Concatenate; require identical structure (for now)
  if sub_concat and super_concat then
    local sub_prefix = rawget(sub_params, 'prefix')
    local sub_ps = rawget(sub_params, 'param_spec')
    local super_prefix = rawget(super_params, 'prefix')
    local super_ps = rawget(super_params, 'param_spec')
    if #sub_prefix ~= #super_prefix then
      return false
    end
    for i = 1, #sub_prefix do
      if not is_subtype_impl(super_prefix[i], sub_prefix[i],
                             in_progress) then
        return false
      end
    end
    if rawequal(sub_ps, super_ps) then
      return true
    end
    if unify.unifiable_params[sub_ps] then
      return bind_param_spec(unify, sub_ps, super_ps)
    end
    if unify.unifiable_params[super_ps] then
      return bind_param_spec(unify, super_ps, sub_ps)
    end
    return false
  end
  -- Exactly one side is Concatenate; extract its prefix and ParamSpec
  local concat, other, is_sub
  if sub_concat then
    concat = sub_params
    other = super_params
    is_sub = true
  else
    concat = super_params
    other = sub_params
    is_sub = false
  end
  local prefix = rawget(concat, 'prefix')
  local concat_ps = rawget(concat, 'param_spec')
  -- Validate that the other side has enough elements for the prefix
  if type(other) ~= 'table' or #other < #prefix then
    return false
  end
  -- Compare the fixed prefix. The variance depends on which side is
  -- Concatenate: if it's on the candidate side (sub), then the prefix
  -- comparison is contravariant (is_subtype(super, sub) pointwise, with
  -- super=other, sub=concat prefix); if it's on the super side, then
  -- it's covariant (is_subtype(concat_prefix, other_prefix)).
  for i = 1, #prefix do
    if is_sub then
      if not is_subtype_impl(other[i], prefix[i], in_progress) then
        return false
      end
    else
      if not is_subtype_impl(prefix[i], other[i], in_progress) then
        return false
      end
    end
  end
  -- Capture the remainder of other into concat_ps
  local remainder = {}
  for i = #prefix + 1, #other do
    remainder[i - #prefix] = other[i]
  end
  if unify.unifiable_params[concat_ps] then
    return bind_param_spec(unify, concat_ps, remainder)
  end
  return false
end

-- Decides a parameter position where at least one side stands in as a
-- ParamSpec or Concatenate (after resolve_param_spec already substituted
-- any *bound* ParamSpec). A unifiable (candidate-side) ParamSpec captures
-- its counterpart's whole list; a ParamSpec that is not unifiable --
-- declared by super, or shared by both sides -- stays universal and is
-- compatible only with the identical ParamSpec object. A Concatenate
-- wraps a fixed prefix and a ParamSpec; the prefix is compared
-- contravariantly and the remainder is captured by the ParamSpec.
-- Returns true when the parameter position is satisfied (returns are
-- still compared by signature_rules afterward).
local function param_spec_compatible(sub_params, super_params,
                                     in_progress)
  local unify = in_progress[unify_key]
  -- Handle Concatenate composition if either side is a Concatenate
  if is_concatenate(sub_params) or is_concatenate(super_params) then
    return concatenate_compatible(sub_params, super_params, in_progress)
  end
  local sub_ps = is_param_spec(sub_params)
  local super_ps = is_param_spec(super_params)
  -- The same ParamSpec object on both sides (the universal,
  -- both-sides case) is trivially compatible without a binding.
  if sub_ps and super_ps and rawequal(sub_params, super_params) then
    return true
  end
  if super_ps and unify.unifiable_params[super_params] then
    return bind_param_spec(unify, super_params, sub_params)
  end
  if sub_ps and unify.unifiable_params[sub_params] then
    return bind_param_spec(unify, sub_params, super_params)
  end
  return false
end

-- Savepoint/rollback pair for speculative branches: an alternative
-- that records bindings and then fails must not leave them behind
-- for the next alternative (the type-level analog of the
-- value-level save_type_var_bindings in llx.types.matchers). A nil
-- savepoint means no unification scope was active; rollback is then
-- a no-op. Conjunctive walks need no savepoints: their first
-- failure fails the whole enclosing comparison, and the enclosing
-- choice point (or the scope's discard) cleans up.
local function unify_savepoint(in_progress)
  local unify = in_progress[unify_key]
  if unify == nil then
    return nil
  end
  return #unify.log
end

local function unify_rollback(in_progress, savepoint)
  if savepoint == nil then
    return
  end
  local unify = in_progress[unify_key]
  local log, bindings = unify.log, unify.bindings
  local param_bindings = unify.param_bindings
  local tuple_bindings = unify.tuple_bindings
  for i = #log, savepoint + 1, -1 do
    -- The log interleaves TypeVar, ParamSpec, and TypeVarTuple keys;
    -- each key is a distinct object, so clearing it from all three
    -- binding tables is unambiguous (only one ever held it).
    bindings[log[i]] = nil
    param_bindings[log[i]] = nil
    tuple_bindings[log[i]] = nil
    log[i] = nil
  end
end

-- TypeVarTuple/Unpack unification (llx.types.matchers.Unpack): the
-- variadic-generic analog of TypeVar unification, binding a *sequence*
-- of types rather than one. An Unpack(Ts) spliced into a list
-- (candidate side) captures the counterpart's spanned sub-sequence --
-- the positions left over after aligning the fixed prefix and suffix
-- around it -- verbatim on first occurrence, exactly as a ParamSpec
-- captures a whole list one level up; later occurrences substitute the
-- captured sequence before the arity checks. Super-side (universal)
-- Unpacks stay universal, matching only an identical Unpack.

-- Position of the (single) Unpack entry in a list and its wrapped
-- TypeVarTuple, or (nil, nil).
local function find_unpack(list)
  for i = 1, #list do
    if is_unpack(list[i]) then
      return i, rawget(list[i], 'type_var_tuple')
    end
  end
  return nil, nil
end

-- Whether a list ends in a variadic tail (an unchecked VARARG or a
-- typed Rest(T)) -- an unbounded region with no finite type sequence
-- to capture.
local function list_has_variadic_tail(list)
  local last = list[#list]
  return last == VARARG or is_rest(last)
end

-- Returns a copy of `list` with every Unpack(Ts) whose Ts is already
-- captured expanded in place into the bound sequence; the list is
-- returned unchanged (same reference) when nothing was expanded, so
-- the common no-binding path pays nothing.
local function substitute_unpack(list, unify)
  if unify == nil then
    return list
  end
  local out, changed = nil, false
  for i = 1, #list do
    local entry = list[i]
    local seq = is_unpack(entry)
        and unify.tuple_bindings[rawget(entry, 'type_var_tuple')]
        or nil
    if seq ~= nil then
      if not changed then
        out = {}
        for k = 1, i - 1 do
          out[k] = list[k]
        end
        changed = true
      end
      for _, ty in ipairs(seq) do
        out[#out + 1] = ty
      end
    elseif changed then
      out[#out + 1] = entry
    end
  end
  if not changed then
    return list
  end
  return out
end

-- Occurs check for a TypeVarTuple capture: refuses a captured sequence
-- that itself reaches Ts through an Unpack, which would make later
-- substitutions self-referential. A backstop, like the TypeVar and
-- ParamSpec occurs checks: the apartness rule already excludes every
-- self-occurrence the structural walk can see.
local function tvt_occurs(tvt, seq)
  local tvts = {}
  for _, ty in ipairs(seq) do
    collect_type_vars(ty, {}, {}, nil, tvts)
  end
  return tvts[tvt] == true
end

-- Instantiates the unifiable TypeVarTuple `tvt` as the captured
-- sequence `seq`. Records the binding in the shared log so a
-- speculative branch can roll it back, exactly as bind_param_spec
-- does one level up.
local function bind_type_var_tuple(unify, tvt, seq)
  if tvt_occurs(tvt, seq) then
    return false
  end
  unify.tuple_bindings[tvt] = seq
  unify.log[#unify.log + 1] = tvt
  return true
end

-- Decides two lists where at least one carries an Unpack (after any
-- bound sequence was substituted away). `first`/`second` are oriented
-- so the pointwise fixed-position relation is is_subtype_impl(first,
-- second): tuple elements and return lists pass (sub, super); the
-- contravariant parameter list passes (super, sub). Capture is
-- orientation-independent -- the unifiable side grabs the other's
-- spanned region verbatim -- so a single function serves both
-- variances.
local function unpack_capture(first, fi, ftvt, second, si, stvt,
                              in_progress)
  local unify = in_progress[unify_key]
  if ftvt ~= nil and stvt ~= nil then
    -- Both sides carry an Unpack. Only the identical (universal,
    -- both-sides) variable is related in this first iteration:
    -- require aligned prefix/suffix and compare those fixed positions
    -- pointwise. Two *different* variadic variables have no sound
    -- sequence relation yet.
    if not rawequal(ftvt, stvt) then
      return false
    end
    local f_pre, s_pre = fi - 1, si - 1
    local f_suf, s_suf = #first - fi, #second - si
    if f_pre ~= s_pre or f_suf ~= s_suf then
      return false
    end
    for k = 1, f_pre do
      if not is_subtype_impl(first[k], second[k], in_progress) then
        return false
      end
    end
    for k = 1, f_suf do
      if not is_subtype_impl(first[fi + k], second[si + k],
                             in_progress) then
        return false
      end
    end
    return true
  end
  -- Exactly one side carries an Unpack; it must be unifiable
  -- (candidate side) and captures the other side's spanned region.
  local uidx, utvt, other, ulen
  if ftvt ~= nil then
    uidx, utvt, other, ulen = fi, ftvt, second, #first
  else
    uidx, utvt, other, ulen = si, stvt, first, #second
  end
  if unify == nil or not unify.unifiable_tuples[utvt] then
    -- A universal (super-side or shared) Unpack: no concrete list
    -- witnesses "for every sequence", so it relates only to an
    -- identical Unpack (handled above).
    return false
  end
  -- Capturing a finite sequence from a variadic (Rest/VARARG)
  -- counterpart region is undefined in this first iteration; refuse.
  if list_has_variadic_tail(other) then
    return false
  end
  local pre = uidx - 1
  local suf = ulen - uidx
  local n = #other
  if n < pre + suf then
    return false
  end
  -- Capture and bind the spanned region *before* comparing the fixed
  -- prefix/suffix, so a nested occurrence of the same Ts in a
  -- prefix/suffix position (e.g. {Unpack(Ts), Tuple{Unpack(Ts)}})
  -- substitutes this binding and is checked against it, rather than
  -- capturing an independent sequence that the top-level bind would
  -- then silently overwrite. The counterpart's span is captured
  -- verbatim; an empty span (n == pre + suf) binds Ts to the empty
  -- sequence. A failed prefix/suffix comparison below leaves the
  -- binding for the nearest choice point to roll back (or the scope
  -- to discard), exactly as a nested capture that later fails does.
  local span = {}
  for k = pre + 1, n - suf do
    span[#span + 1] = other[k]
  end
  if not bind_type_var_tuple(unify, utvt, span) then
    return false
  end
  for k = 1, pre do
    if not is_subtype_impl(first[k], second[k], in_progress) then
      return false
    end
  end
  for k = 1, suf do
    if not is_subtype_impl(first[#first - suf + k],
                           second[#second - suf + k],
                           in_progress) then
      return false
    end
  end
  return true
end

-- Whether a list carries a top-level Unpack(Ts) entry.
local function list_contains_unpack(list)
  for i = 1, #list do
    if is_unpack(list[i]) then
      return true
    end
  end
  return false
end

-- unpack_capture for a pair of signature lists, locating each side's
-- Unpack for the caller. `first`/`second` are oriented so the
-- pointwise relation is is_subtype_impl(first, second). Precondition:
-- at least one list carries an Unpack.
local function unpack_lists_compatible(first, second, in_progress)
  local fi, ftvt = find_unpack(first)
  local si, stvt = find_unpack(second)
  return unpack_capture(first, fi, ftvt, second, si, stvt, in_progress)
end

-- Covariant structural relation over two Tuple element *lists* (raw
-- type lists that may carry a trailing VARARG/Rest tail but no
-- Unpack). Factored out so the precomputed-shape fast path and the
-- Unpack path (after substituting bound sequences) share it.
local function tuple_list_shape(types)
  local n = #types
  local last = types[n]
  if last == VARARG then
    return n - 1, true, nil
  end
  if is_rest(last) then
    return n - 1, true, rawget(last, 'element_type')
  end
  return n, false, nil
end

local function tuple_list_subtype(a_types, b_types, in_progress)
  local a_fixed, a_variadic, a_rest = tuple_list_shape(a_types)
  local b_fixed, b_variadic, b_rest = tuple_list_shape(b_types)
  if b_variadic then
    if a_fixed < b_fixed then
      return false
    end
  elseif a_variadic or a_fixed ~= b_fixed then
    return false
  end
  local b_tail = b_rest or Any
  for i = 1, a_fixed do
    local expected = i <= b_fixed and b_types[i] or b_tail
    if not is_subtype_impl(a_types[i], expected, in_progress) then
      return false
    end
  end
  if a_variadic then
    local a_tail = a_rest or Any
    if not is_subtype_impl(a_tail, b_tail, in_progress) then
      return false
    end
  end
  return true
end

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
--
-- When either matcher splices an Unpack(Ts), the comparison routes
-- through the sequence-unification path instead (see unpack_capture):
-- the spanned region binds Ts, and any already-bound Ts is
-- substituted before the covariant relation applies.
local function tuple_subtype(a, b, in_progress)
  if rawget(a, 'unpack_index') ~= nil
      or rawget(b, 'unpack_index') ~= nil then
    local unify = in_progress[unify_key]
    local a_types =
        substitute_unpack(rawget(a, 'element_types'), unify)
    local b_types =
        substitute_unpack(rawget(b, 'element_types'), unify)
    local ai, atvt = find_unpack(a_types)
    local bi, btvt = find_unpack(b_types)
    if atvt == nil and btvt == nil then
      -- Both Unpacks were bound and expanded away: plain relation.
      return tuple_list_subtype(a_types, b_types, in_progress)
    end
    return unpack_capture(a_types, ai, atvt, b_types, bi, btvt,
                          in_progress)
  end
  return tuple_list_subtype(rawget(a, 'element_types'),
                            rawget(b, 'element_types'), in_progress)
end

-- ---------------------------------------------------------------------
-- Schema structural subtyping (llx.schema.Schema).
--
-- A schema NARROWS a type with value-level constraints, so the relation
-- between two schemas is containment of the value sets they accept:
-- every value satisfying `a` must satisfy `b`. That is decided per
-- constraint against what `b` imposes -- a bound `b` does not set
-- constrains nothing, and `a` may be arbitrarily stricter.
--
-- Without this rule two schemas fall through to the __name fallback,
-- which is wrong in BOTH directions: every untitled schema is named
-- 'Schema' (so unrelated shapes compare mutually equal), while two
-- schemas sharing a `title` compare equal whatever their fields say.
--
-- EVERY RULE HERE MIRRORS THE VALUE LEVEL, which is where "satisfies"
-- is defined (llx.schema's check_field / check_constraints and the
-- per-type __validate hooks). Two consequences are easy to get wrong
-- and are handled explicitly below:
--
-- - Type-specific constraints are enforced ONLY by the __validate hook
--   of the schema's declared `type`. A `minimum` on a Union-typed
--   schema, `properties` on a List-typed one, or `prefix_items` with no
--   `items` alongside it are all DEAD -- the value level never reads
--   them. A dead constraint must not be credited as a narrowing on the
--   subtype side (that would accept values the supertype rejects), nor
--   demanded on the supertype side. See schema_enforces / effective.
-- - A schema with no `type` accepts NOTHING: check_field raises on it.
--   It is treated as undecidable rather than as a top type.
--
-- The rule is SOUND-leaning: where containment cannot be established --
-- an arbitrary `predicate`, two different `pattern`s, a field `a` leaves
-- unconstrained -- it returns false rather than admit a value `b`
-- rejects. The structural verdict is final, like Tuple's.
-- ---------------------------------------------------------------------

-- Every key that narrows a schema's value set. A key outside this list
-- (title, __name, __isinstance, default, ui_hint) is metadata and does
-- not affect the relation.
local schema_constraint_keys = {
  'minimum', 'exclusive_minimum', 'maximum', 'exclusive_maximum',
  'multiple_of', 'min_length', 'max_length', 'pattern',
  'properties', 'required', 'items', 'prefix_items',
  'type_schemas', 'one_of', 'predicate',
}

-- Which declared type enforces which constraint group. Resolved lazily
-- and memoized: llx.types.list pulls in llx.class, and requiring that
-- graph at this module's load time risks a cycle. Integer and Float
-- alias Number's hook (llx.types.integer / .float assign it directly),
-- so one function identity covers the whole numeric tower.
local constraint_hooks_cache = nil
local function constraint_hooks()
  if constraint_hooks_cache == nil then
    constraint_hooks_cache = {
      numeric = require('llx.types.number').Number.__validate,
      length = require('llx.types.string').String.__validate,
      shape = require('llx.types.table').Table.__validate,
      items = require('llx.types.list').List.__validate,
    }
  end
  return constraint_hooks_cache
end

-- The __validate hook a declared type will actually run, or nil when it
-- has none (in which case every type-specific constraint on a schema of
-- that type is dead). pcall-guarded: llx module proxies raise on a
-- missing field rather than returning nil.
local function validate_hook(schema_type)
  if type(schema_type) ~= 'table' then
    return nil
  end
  local ok, hook = pcall(function() return schema_type.__validate end)
  if not ok or type(hook) ~= 'function' then
    return nil
  end
  return hook
end

-- True when `s`'s declared type really enforces `group`, so a constraint
-- in that group is live rather than dead metadata.
local function schema_enforces(s, group)
  local hook = validate_hook(rawget(s, 'type'))
  return hook ~= nil and hook == constraint_hooks()[group]
end

-- `s`'s value for a constraint key, or nil when the key is dead for
-- `s`'s declared type. `group` nil marks a type-agnostic constraint
-- (check_constraints runs one_of / predicate whatever the type is).
local function effective(s, key, group)
  if group ~= nil and not schema_enforces(s, group) then
    return nil
  end
  return rawget(s, key)
end

-- `prefix_items` is read only inside List's __validate *after* it has
-- returned early on a missing `items` (see llx.types.list), so a
-- prefix-only list schema constrains nothing.
local function effective_prefix_items(s)
  if effective(s, 'items', 'items') == nil then
    return nil
  end
  return rawget(s, 'prefix_items')
end

-- `type_schemas` (per-member schemas for a union-typed schema) is
-- enforced by the Union matcher's own __validate. Union builds that hook
-- per instance, so it cannot be recognized by function identity like the
-- others; a union-typed schema is the condition.
local function effective_type_schemas(s)
  if union_members(rawget(s, 'type')) == nil then
    return nil
  end
  return rawget(s, 'type_schemas')
end

-- A schema: either a wrapper built by llx.schema.Schema (marked on its
-- METATABLE, so the marker never shows up in pairs() / repr / the key
-- enumeration llx.export's consumers rely on) or a plain
-- {type = ..., <constraints>} definition table. The structural arm
-- matters: check_field accepts a bare definition table exactly as it
-- accepts a wrapper, nested definitions are routinely written that way,
-- and llx.export's ensure_schema hands back an already-__isinstance
-- table unwrapped. Recognizing both keeps one verdict at every depth.
local function is_schema(t)
  if type(t) ~= 'table' then
    return false
  end
  local mt = getmetatable(t)
  if mt ~= nil and rawget(mt, '__is_llx_schema') == true then
    return true
  end
  return rawget(t, 'type') ~= nil
end

-- True when `s` narrows nothing, so it accepts exactly the values of its
-- own `type` and is interchangeable with that bare type. Dead
-- constraints do not count -- the value level ignores them too.
local function schema_is_unconstrained(s)
  for _, key in ipairs(schema_constraint_keys) do
    if rawget(s, key) ~= nil and effective(s, key, nil) ~= nil then
      -- Re-read through the group gate so a dead constraint (a
      -- `minimum` on a Union-typed schema, say) is not mistaken for a
      -- narrowing.
      local live
      if key == 'prefix_items' then
        live = effective_prefix_items(s)
      elseif key == 'type_schemas' then
        live = effective_type_schemas(s)
      elseif key == 'minimum' or key == 'exclusive_minimum'
          or key == 'maximum' or key == 'exclusive_maximum'
          or key == 'multiple_of' then
        live = effective(s, key, 'numeric')
      elseif key == 'min_length' or key == 'max_length'
          or key == 'pattern' then
        live = effective(s, key, 'length')
      elseif key == 'properties' or key == 'required' then
        live = effective(s, key, 'shape')
      elseif key == 'items' then
        live = effective(s, key, 'items')
      else
        live = rawget(s, key)
      end
      if live ~= nil then
        return false
      end
    end
  end
  return true
end

-- True when `s` accepts EVERY value: unconstrained, and typed at the top
-- (Any) or gradual (Dynamic). Used where `a` leaves a field `b`
-- constrains unspecified -- only a `b` field that forbids nothing can
-- accept whatever `a` lets through there. A schema with no `type` is not
-- permissive but unsatisfiable (check_field raises on it), so it is
-- excluded.
local function schema_accepts_anything(s)
  local schema_type = rawget(s, 'type')
  if schema_type == nil then
    return false
  end
  if not (rawequal(schema_type, Any) or rawequal(schema_type, Dynamic)) then
    return false
  end
  return schema_is_unconstrained(s)
end

-- A bound is usable only when it is a real number. This is not
-- defensive trimming, it is the value level: number.lua compares with
-- `<` / `>`, so a NaN bound never rejects anything (an absent bound) and
-- a non-numeric one would raise a raw comparison error out of
-- is_subtype instead of yielding a verdict.
local function numeric_bound(value)
  if type(value) ~= 'number' or value ~= value then
    return nil
  end
  return value
end

-- The effective floor `s` imposes as (value, inclusive), or nil for
-- none. `minimum` and `exclusive_minimum` may both be present; the
-- tighter (greater) one wins, and at equal values the exclusive bound is
-- the tighter of the two.
local function schema_lower_bound(s)
  local inclusive = numeric_bound(effective(s, 'minimum', 'numeric'))
  local exclusive =
      numeric_bound(effective(s, 'exclusive_minimum', 'numeric'))
  if exclusive ~= nil and (inclusive == nil or exclusive >= inclusive) then
    return exclusive, false
  end
  if inclusive ~= nil then
    return inclusive, true
  end
  return nil
end

-- Symmetric to schema_lower_bound; the tighter ceiling is the lesser.
local function schema_upper_bound(s)
  local inclusive = numeric_bound(effective(s, 'maximum', 'numeric'))
  local exclusive =
      numeric_bound(effective(s, 'exclusive_maximum', 'numeric'))
  if exclusive ~= nil and (inclusive == nil or exclusive <= inclusive) then
    return exclusive, false
  end
  if inclusive ~= nil then
    return inclusive, true
  end
  return nil
end

-- `a`'s floor is at least as high as `b`'s, so `a` admits no value below
-- what `b` permits. A `b` with no floor constrains nothing; an `a` with
-- no floor under a `b` that has one admits values `b` rejects.
local function lower_contained(a, b)
  local b_value, b_inclusive = schema_lower_bound(b)
  if b_value == nil then
    return true
  end
  local a_value, a_inclusive = schema_lower_bound(a)
  if a_value == nil then
    return false
  end
  if a_value > b_value then
    return true
  end
  if a_value < b_value then
    return false
  end
  -- Equal bounds: `a` is contained unless it admits the endpoint `b`
  -- excludes.
  return b_inclusive or not a_inclusive
end

local function upper_contained(a, b)
  local b_value, b_inclusive = schema_upper_bound(b)
  if b_value == nil then
    return true
  end
  local a_value, a_inclusive = schema_upper_bound(a)
  if a_value == nil then
    return false
  end
  if a_value < b_value then
    return true
  end
  if a_value > b_value then
    return false
  end
  return b_inclusive or not a_inclusive
end

-- A usable divisor. Lua's `%` is floored, so `x % -n == 0` exactly when
-- `x % n == 0`: a negative divisor constrains the same set as its
-- magnitude, and only the magnitude matters here. Zero would raise on
-- an integer `%`, and NaN rejects every value, so neither yields a
-- containment we can reason about.
local function divisor(value)
  local n = numeric_bound(value)
  if n == nil or n == 0 then
    return nil
  end
  return n < 0 and -n or n
end

-- Every value `a` admits is a multiple of `b`'s divisor exactly when
-- `a`'s divisor is itself a multiple of `b`'s. A `b` divisor we cannot
-- reason about is refused rather than interpreted.
local function multiple_of_contained(a, b)
  local b_raw = effective(b, 'multiple_of', 'numeric')
  if b_raw == nil then
    return true
  end
  local b_divisor = divisor(b_raw)
  if b_divisor == nil then
    return false
  end
  local a_divisor = divisor(effective(a, 'multiple_of', 'numeric'))
  if a_divisor == nil then
    return false
  end
  return a_divisor % b_divisor == 0
end

-- `b`'s length window contains `a`'s, and `b`'s pattern is `a`'s. Regex
-- containment is undecidable here, so an identical pattern is required --
-- the sound-leaning choice.
local function length_contained(a, b)
  local b_min = numeric_bound(effective(b, 'min_length', 'length'))
  if b_min ~= nil then
    local a_min = numeric_bound(effective(a, 'min_length', 'length'))
    if a_min == nil or a_min < b_min then
      return false
    end
  end
  local b_max = numeric_bound(effective(b, 'max_length', 'length'))
  if b_max ~= nil then
    local a_max = numeric_bound(effective(a, 'max_length', 'length'))
    if a_max == nil or a_max > b_max then
      return false
    end
  end
  local b_pattern = effective(b, 'pattern', 'length')
  if b_pattern ~= nil
      and effective(a, 'pattern', 'length') ~= b_pattern then
    return false
  end
  return true
end

-- With `b` restricting values to a fixed set, `a` must restrict to a
-- subset of it. An `a` that lists nothing admits values outside `b`'s
-- set. A non-list `one_of` cannot be walked, so it is refused rather
-- than raising out of is_subtype.
local function one_of_contained(a, b)
  local b_values = effective(b, 'one_of', nil)
  if b_values == nil then
    return true
  end
  if type(b_values) ~= 'table' then
    return false
  end
  local a_values = effective(a, 'one_of', nil)
  if type(a_values) ~= 'table' then
    return false
  end
  for _, a_value in ipairs(a_values) do
    local found = false
    for _, b_value in ipairs(b_values) do
      if a_value == b_value then
        found = true
        break
      end
    end
    if not found then
      return false
    end
  end
  return true
end

-- An arbitrary Lua predicate is opaque -- nothing can be proven about
-- the set it accepts -- so containment holds only when `a` runs the very
-- same predicate.
local function predicate_contained(a, b)
  local b_predicate = effective(b, 'predicate', nil)
  if b_predicate == nil then
    return true
  end
  return effective(a, 'predicate', nil) == b_predicate
end

local function list_contains(list, value)
  for i = 1, #list do
    if list[i] == value then
      return true
    end
  end
  return false
end

-- Whether a nested schema position `b_entry` constrains nothing, so an
-- `a` that leaves the same position unspecified still relates.
local function position_forbids_nothing(b_entry)
  return is_schema(b_entry) and schema_accepts_anything(b_entry)
end

-- Table shape. Width subtyping: `a` may carry properties beyond `b`'s.
-- Shared properties recurse. A field `b` constrains but `a` leaves
-- unspecified is the unsound case -- `a` admits any value there,
-- including ones `b` rejects -- so it holds only when `b`'s field
-- forbids nothing.
--
-- `required` is subtler than it looks: Table's __validate enforces it
-- only for names that ALSO appear in `properties` (the presence check
-- lives inside the `pairs(properties)` walk), so a name required without
-- a property spec is never enforced and cannot be credited as a
-- presence guarantee.
local function properties_contained(a, b, in_progress)
  local a_properties = effective(a, 'properties', 'shape')
  local b_properties = effective(b, 'properties', 'shape')
  local b_required = effective(b, 'required', 'shape')
  if b_required ~= nil and b_properties ~= nil then
    local a_required = effective(a, 'required', 'shape')
    for _, name in ipairs(b_required) do
      if b_properties[name] ~= nil then
        local guaranteed = a_required ~= nil
            and a_properties ~= nil
            and a_properties[name] ~= nil
            and list_contains(a_required, name)
        if not guaranteed then
          return false
        end
      end
    end
  end
  if b_properties == nil then
    return true
  end
  for name, b_property in pairs(b_properties) do
    local a_property = a_properties ~= nil and a_properties[name] or nil
    if a_property == nil then
      if not position_forbids_nothing(b_property) then
        return false
      end
    elseif not is_subtype_impl(a_property, b_property, in_progress) then
      return false
    end
  end
  return true
end

-- List shape: `items` applies to every element, `prefix_items` per
-- position (and only alongside `items`; see effective_prefix_items).
-- Both are covariant -- a list schema describes values its holder
-- observes -- and an element constraint `b` sets that `a` lacks holds
-- only when `b`'s constraint forbids nothing, as for a table property.
-- A longer `a` prefix is narrower, so only a SHORTER one is refused.
local function items_contained(a, b, in_progress)
  local b_items = effective(b, 'items', 'items')
  if b_items ~= nil then
    local a_items = effective(a, 'items', 'items')
    if a_items == nil then
      if not position_forbids_nothing(b_items) then
        return false
      end
    elseif not is_subtype_impl(a_items, b_items, in_progress) then
      return false
    end
  end
  local b_prefix = effective_prefix_items(b)
  if b_prefix ~= nil then
    local a_prefix = effective_prefix_items(a)
    if a_prefix == nil or #a_prefix < #b_prefix then
      return false
    end
    for i = 1, #b_prefix do
      if not is_subtype_impl(a_prefix[i], b_prefix[i], in_progress) then
        return false
      end
    end
  end
  return true
end

-- Per-union-member schemas. Same shape as properties: every member `b`
-- constrains must be constrained at least as strictly by `a`, and a
-- member `a` leaves unspecified relates only when `b`'s entry forbids
-- nothing.
local function type_schemas_contained(a, b, in_progress)
  local b_schemas = effective_type_schemas(b)
  if b_schemas == nil then
    return true
  end
  local a_schemas = effective_type_schemas(a)
  for name, b_entry in pairs(b_schemas) do
    local a_entry = a_schemas ~= nil and a_schemas[name] or nil
    if a_entry == nil then
      if not position_forbids_nothing(b_entry) then
        return false
      end
    elseif not is_subtype_impl(a_entry, b_entry, in_progress) then
      return false
    end
  end
  return true
end

-- The relation between two schemas. The declared types relate first
-- (every value `a` admits is an `a.type`, and must be usable as a
-- `b.type` -- which is where Union / Optional / class / numeric-tower
-- rules all come in, since a schema spells those in its `type` field),
-- then each constraint group `b` imposes. A schema with no declared type
-- accepts nothing (check_field raises on it), so it is undecidable here
-- rather than a top type.
local function schema_subtype(a, b, in_progress)
  local a_type = rawget(a, 'type')
  local b_type = rawget(b, 'type')
  if a_type == nil or b_type == nil then
    return false
  end
  if not is_subtype_impl(a_type, b_type, in_progress) then
    return false
  end
  return lower_contained(a, b)
     and upper_contained(a, b)
     and multiple_of_contained(a, b)
     and length_contained(a, b)
     and one_of_contained(a, b)
     and predicate_contained(a, b)
     and properties_contained(a, b, in_progress)
     and items_contained(a, b, in_progress)
     and type_schemas_contained(a, b, in_progress)
end

-- The relation proper, applied to resolved operands. is_subtype_impl
-- wraps it with Lazy resolution and the cycle-guard bookkeeping;
-- the public is_subtype below documents the rules.
local function subtype_rules(a, b, in_progress)
  -- Dynamic is the GRADUAL type (llx.types.matchers.Dynamic; mypy's
  -- Any): it stands for "statically unknown", so the relation defers
  -- to runtime instead of rejecting -- Dynamic is both a subtype and
  -- a supertype of every type. Checked first so it applies at every
  -- position the structural rules recurse into (container elements,
  -- tuple slots, Callable parameters and returns, union members),
  -- making e.g. ListOf(Dynamic) and ListOf(Integer) mutual subtypes.
  -- This is deliberately gradual, not sound -- exactly Any's
  -- accept-direction policy, in both directions. It also precedes the
  -- TypeVar rule: a variable checked against Dynamic is compatible
  -- without binding, in either role, so a generic signature never
  -- instantiates a variable to Dynamic merely because the counterpart
  -- was unannotated.
  if rawequal(a, Dynamic) or rawequal(b, Dynamic) then
    return true
  end
  -- TypeVars (llx.types.matchers.TypeVar). Outside a signature
  -- comparison a type variable stands for a per-call binding, not a
  -- concrete type, so the only sound relations are identity (a
  -- variable is trivially a subtype of itself) and widening to the
  -- top type (every binding is a subtype of Any). Everything else --
  -- including is_subtype(T, T.bound), which the value-level bound
  -- check does not justify for structural bounds, and
  -- is_subtype(Never, T) for a TypeVar T -- is conservatively
  -- false. Checked before the name-equality rule below so two
  -- distinct TypeVars sharing a name are never conflated.
  --
  -- Inside a signature comparison (a unification scope is active;
  -- see signature_compatible_impl), variables declared by the
  -- candidate (sub) signature additionally unify: the variable's
  -- first comparison against a counterpart instantiates it (subject
  -- to its bound and the occurs check; see bind_type_var), and
  -- every later occurrence resolves to that instantiation and is
  -- compared with the position's own variance -- exactly the check
  -- "substitute the instantiation, then decide structurally".
  -- Variables from the super side (or outside the scope's sub) are
  -- never instantiated: super promises to work for every binding,
  -- which no single instantiation can witness. An unbound sub
  -- variable may instantiate *to* such a universal variable, which
  -- is sound pointwise (for every binding of the universal variable
  -- the same substitution works), so alpha-equivalent generic
  -- signatures relate.
  if is_type_var(a) or is_type_var(b) then
    if rawequal(a, b) or rawequal(b, Any) then
      return true
    end
    local unify = in_progress[unify_key]
    if unify == nil then
      return false
    end
    local binding_a = is_type_var(a) and unify.bindings[a] or nil
    local binding_b = is_type_var(b) and unify.bindings[b] or nil
    if binding_a ~= nil or binding_b ~= nil then
      return is_subtype_impl(binding_a or a, binding_b or b,
                             in_progress)
    end
    if is_type_var(b) and unify.unifiable[b] then
      return bind_type_var(unify, b, a, in_progress)
    end
    if is_type_var(a) and unify.unifiable[a] then
      return bind_type_var(unify, a, b, in_progress)
    end
    return false
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
  -- Schemas (llx.schema.Schema) compare structurally, ahead of the name
  -- fallback: every untitled schema is named 'Schema', so that fallback
  -- relates unrelated shapes in both directions, and two schemas sharing
  -- a title compare equal whatever their fields say. See schema_subtype
  -- above; like the other structural rules the verdict is final.
  --
  -- A string counterpart is excluded throughout: a string type name
  -- carries no structure to compare against, and a Signature declaration
  -- may name a schema by its title -- which is exactly the __name
  -- equality type_equal implements further down.
  local a_is_schema = type(b) ~= 'string' and is_schema(a)
  local b_is_schema = type(a) ~= 'string' and is_schema(b)
  if a_is_schema and b_is_schema then
    return rawequal(a, b) or schema_subtype(a, b, in_progress)
  end
  -- A schema against a bare type. A schema only ever NARROWS its type,
  -- so it erases in one direction -- every value of Schema{type = T} is
  -- a T -- while the reverse holds only for a schema that constrains
  -- nothing, since a bare T admits values any real constraint rejects.
  if a_is_schema then
    -- A union counterpart gets the member walk FIRST, so a schema member
    -- is decided by the schema-pair rule above instead of being erased
    -- past its constraints. Erasure is still tried afterwards, so an
    -- unconstrained schema over a union type stays a subtype of that
    -- union. Each member is a speculative alternative, so a failed
    -- branch rolls its TypeVar instantiations back.
    local b_union = union_members(b)
    if b_union ~= nil then
      for _, member in ipairs(b_union) do
        local savepoint = unify_savepoint(in_progress)
        if is_subtype_impl(a, member, in_progress) then
          return true
        end
        unify_rollback(in_progress, savepoint)
      end
    end
    return is_subtype_impl(rawget(a, 'type'), b, in_progress)
  end
  if b_is_schema and union_members(a) == nil then
    return schema_is_unconstrained(b)
       and is_subtype_impl(a, rawget(b, 'type'), in_progress)
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
  -- Parameterized matchers of the same kind (ListOf, SetOf, Dict,
  -- Callable, GenericAlias -- told apart by the kind mark their constructors
  -- record; see llx.types.matchers.matcher_kind) likewise compare
  -- structurally, taking precedence over the name fallback for the
  -- same reasons as Tuples, and the structural verdict -- either
  -- way -- is final. Matchers of *different* kinds fall through to
  -- the rules below (their spelled names never collide, so the
  -- fallback keeps, say, ListOf(T) and SetOf(T) unrelated). rawequal
  -- keeps the relation reflexive for recursive matchers without a
  -- self-dependent element walk.
  local a_kind = matcher_kind(a)
  if a_kind ~= nil and a_kind == matcher_kind(b) then
    if rawequal(a, b) then
      return true
    end
    if a_kind == 'GenericAlias' then
      -- Parameterized generic-class aliases (matchers.GenericAlias:
      -- Pool[Integer]). Two aliases relate only over the SAME origin
      -- class; the arguments then compare under each declared
      -- parameter's variance ('invariant' = mutual subtypes,
      -- 'covariant', 'contravariant' -- see llx.class's generic).
      -- Aliases of DIFFERENT origins are unrelated even when the
      -- origins are: mapping arguments through an inheritance chain
      -- (Python's static-checker treatment of Sub(Base[T])) is
      -- deliberately deferred, and the erased relations below
      -- (alias vs bare class) already cover the common
      -- subclass-to-parameterized-base flows. The structural verdict
      -- is final.
      local a_origin = rawget(a, 'origin')
      if a_origin ~= rawget(b, 'origin') then
        return false
      end
      local a_args = rawget(a, 'type_args')
      local b_args = rawget(b, 'type_args')
      local params = a_origin.__type_params or {}
      for i, param in ipairs(params) do
        local variance = param.variance
        if variance == 'covariant' then
          if not is_subtype_impl(a_args[i], b_args[i], in_progress) then
            return false
          end
        elseif variance == 'contravariant' then
          if not is_subtype_impl(b_args[i], a_args[i], in_progress) then
            return false
          end
        else
          if not (is_subtype_impl(a_args[i], b_args[i], in_progress)
                  and is_subtype_impl(b_args[i], a_args[i],
                                      in_progress)) then
            return false
          end
        end
      end
      return true
    end
    if a_kind == 'ListOf' or a_kind == 'SetOf' then
      -- Elements are covariant: like a tuple's slots, the element
      -- position describes values the container's holder observes,
      -- so a container of narrower elements can stand in wherever a
      -- container of wider ones is expected. This treats containers
      -- as value containers (reads); a checker that tracked aliased
      -- mutation would need invariant elements, as mypy's mutable
      -- list does, so covariance here is a deliberate, gradual
      -- choice consistent with the Tuple rule.
      return is_subtype_impl(rawget(a, 'element_type'),
                             rawget(b, 'element_type'), in_progress)
    end
    if a_kind == 'Dict' then
      -- Values are covariant, like ListOf elements. Keys are
      -- invariant (mutual subtypes): a key type occupies both an
      -- output position (iteration yields the keys) and an input
      -- position (lookups take a key), and a type used both ways
      -- admits no variance in either direction -- the same
      -- both-positions argument that makes mypy's Mapping[K, V]
      -- invariant in K. Invariance is checked as mutual is_subtype
      -- rather than name equality so it stays structural:
      -- Dict(Union{A, B}, V) and Dict(Union{B, A}, V) are mutual
      -- subtypes, while Dicts keyed by distinct same-named classes
      -- are not.
      return is_subtype_impl(rawget(a, 'key_type'),
                             rawget(b, 'key_type'), in_progress)
         and is_subtype_impl(rawget(b, 'key_type'),
                             rawget(a, 'key_type'), in_progress)
         and is_subtype_impl(rawget(a, 'value_type'),
                             rawget(b, 'value_type'), in_progress)
    end
    -- Callable: the signature relation decides (parameters
    -- contravariant, returns covariant, with the variadic and
    -- AnyParams rules documented on signature_compatible below),
    -- with the cycle guard threaded through so recursive Callables
    -- trip it instead of overflowing the stack -- except two
    -- matcher-level guards where the matchers' value sets diverge
    -- from the call relation:
    --
    -- - strict tightens only the raw-function fallback of the
    --   value-level check, so a strict Callable -- whose values are
    --   a subset of its lenient counterpart's -- can stand where a
    --   lenient one is expected, but a lenient one, which admits
    --   raw functions of shapes strict rejects, cannot stand where
    --   strict is expected.
    -- - AnyParams as the *subtype*'s parameter list: that matcher
    --   accepts declared functions of every parameter shape
    --   (signature_compatible's AnyParams-as-sub direction is
    --   documented as gradual, not sound), so it can stand only
    --   where the supertype also declares AnyParams. The sound
    --   direction -- a concrete parameter list under an AnyParams
    --   supertype, which constrains nothing -- is exactly what
    --   signature_compatible accepts.
    if rawget(b, 'strict') and not rawget(a, 'strict') then
      return false
    end
    -- The exception's other exception: when the supertype's parameter
    -- list is a ParamSpec, defer to signature_compatible instead of
    -- rejecting here. A unifiable ParamSpec captures the AnyParams-ness
    -- (sound: P := AnyParams), and a universal one is rejected there
    -- anyway, so this guard must not pre-empt that decision.
    if is_any_params(rawget(a, 'params'))
        and not is_any_params(rawget(b, 'params'))
        and not is_param_spec(rawget(b, 'params')) then
      return false
    end
    return signature_compatible_impl(a, b, in_progress)
  end
  -- A parameterized alias against a BARE class (only -- any other
  -- counterpart falls through to the standard rules, so unions still
  -- walk members, Any / Dynamic / Never keep their verdicts, and
  -- unrelated matchers land in the name fallback):
  --
  -- - alias <= class ERASES: Pool[Integer] is a Pool (and a subtype
  --   of Pool's bases), whatever the arguments -- the value-level
  --   reading, where an alias instance IS an origin instance.
  -- - class <= alias is GRADUAL: a bare class reads as
  --   applied-to-Dynamic (an unparameterized Pool makes no argument
  --   promises), mirroring Python's treatment of bare generics as
  --   Pool[Any] and this relation's other gradual choices. Sound
  --   per-argument enforcement is exactly what spelling the alias on
  --   both sides buys.
  if a_kind == 'GenericAlias'
      and type(b) == 'table' and b.__is_llx_class then
    return is_subtype_impl(rawget(a, 'origin'), b, in_progress)
  end
  if matcher_kind(b) == 'GenericAlias'
      and type(a) == 'table' and a.__is_llx_class then
    return is_subtype_impl(a, rawget(b, 'origin'), in_progress)
  end
  -- Two unions also compare member-wise ahead of the name fallback:
  -- a union's name embeds only its members' *names*, so distinct
  -- same-named member types (classes, most visibly) would otherwise
  -- be conflated one wrapper up. The rule is the general union rule
  -- below specialized to a union b -- every a member must be a
  -- subtype of b, each decided against b's member list by the
  -- recursion -- and its verdict is final, like the structural
  -- rules above. rawequal keeps the relation reflexive for
  -- recursive unions without a self-dependent member walk.
  local a_members = union_members(a)
  local b_members = union_members(b)
  if a_members ~= nil and b_members ~= nil then
    if rawequal(a, b) then
      return true
    end
    for _, member in ipairs(a_members) do
      if not is_subtype_impl(member, b, in_progress) then
        return false
      end
    end
    return true
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
  if a_members then
    for _, member in ipairs(a_members) do
      if not is_subtype_impl(member, b, in_progress) then
        return false
      end
    end
    return true
  end
  -- a is a subtype of a union when it is a subtype of any member. A
  -- member that recorded TypeVar instantiations and then failed must
  -- not leak them into the next member's attempt.
  if b_members then
    for _, member in ipairs(b_members) do
      local savepoint = unify_savepoint(in_progress)
      if is_subtype_impl(a, member, in_progress) then
        return true
      end
      unify_rollback(in_progress, savepoint)
    end
    return false
  end
  -- Numeric widening. Only the matcher tables participate; string
  -- type names compare by name equality alone.
  if rawequal(b, Number)
      and (rawequal(a, Integer) or rawequal(a, Float)) then
    return true
  end
  -- Classes: walk the superclass chain transitively. Like the union
  -- member walk above, each base is a speculative alternative, so a
  -- failed branch rolls its TypeVar instantiations back.
  if type(a) == 'table' then
    local superclasses = a.__superclasses
    if superclasses then
      for _, superclass in ipairs(superclasses) do
        local savepoint = unify_savepoint(in_progress)
        if is_subtype_impl(superclass, b, in_progress) then
          return true
        end
        unify_rollback(in_progress, savepoint)
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
-- - `Dynamic` as the gradual type (mypy's `Any`): both a subtype and
--   a supertype of every type, at every STRUCTURALLY COMPARED
--   position -- the rule applies before the structural recursion, so
--   `ListOf(Dynamic)` and `ListOf(Integer)` are mutual subtypes and a
--   `Dynamic` Callable parameter or return is compatible with any
--   typed counterpart in both directions. Inside the name-compared
--   matchers listed in the Caveats below (Iterator, Generator,
--   Protocol, ...) a nested Dynamic is frozen into the name like any
--   other element type, exactly as nested Any is. Deliberately
--   gradual, not sound: use it where statically unknown values meet
--   typed contracts and the check should defer to runtime.
-- - `Never` as the bottom type: `Never` is a subtype of everything,
--   and nothing but `Never` itself (and an uninhabited union, which
--   the union rule accepts vacuously) is a subtype of `Never`.
-- - `Union`: a union is a subtype of `b` when every member is; `a` is
--   a subtype of a union when it is a subtype of any member. Two
--   unions always compare member-wise (never by name), so distinct
--   same-named member types are not conflated one wrapper up.
-- - Numeric widening: `Integer` and `Float` are subtypes of `Number`,
--   mirroring the value level where both satisfy `Number`.
-- - Classes: the transitive `__superclasses` chain is walked, so a
--   derived class is a subtype of each of its bases.
-- - `Tuple`: two Tuple matchers compare structurally, element-wise
--   covariantly, with fixed/variadic arity rules mirroring the
--   return-list rules of `signature_compatible` (see tuple_subtype
--   above). The structural verdict is final: two Tuples never fall
--   back to name equality.
-- - `ListOf`/`SetOf`: two matchers of the same kind compare
--   structurally with covariant element types --
--   `ListOf(Integer)` is a subtype of `ListOf(Number)` -- and the
--   structural verdict is final, as for Tuples. The two kinds stay
--   unrelated to each other.
-- - `Dict`: values compare covariantly; keys are invariant (mutual
--   subtypes), because a key type occupies both an output position
--   (iteration yields keys) and an input position (lookups take a
--   key), the same rule mypy applies to Mapping's key parameter.
--   The structural verdict is final.
-- - `Callable`: two Callable matchers compare by
--   `signature_compatible` (parameters contravariant, returns
--   covariant, with its variadic and AnyParams rules), except that
--   a lenient Callable is never a subtype of a strict one (strict
--   narrows which raw functions are accepted at the value level),
--   and a Callable declaring AnyParams is a subtype only of
--   another AnyParams Callable (its value set spans every
--   parameter shape; the sound direction, a concrete list under an
--   AnyParams supertype, holds). The structural verdict is final.
-- - `GenericAlias` (a parameterized generic class, `Pool[Integer]`):
--   two aliases of the SAME origin compare argument-wise under each
--   declared type parameter's variance (invariant by default;
--   see llx.class's `generic`); aliases of different origins are
--   unrelated (inheritance-mapped arguments are deferred). Against a
--   BARE class, an alias erases (`Pool[Integer]` is a subtype of
--   `Pool` and its bases) and the reverse is gradual (a bare class
--   reads as applied-to-Dynamic). The structural verdict is final.
-- - `Schema` (`llx.schema.Schema`): two schemas compare as containment
--   of the value sets they accept -- their `type` fields relate
--   recursively (which is where a schema's Union / Optional / class /
--   numeric-tower spelling is decided), then every constraint `b`
--   imposes must be met at least as strictly by `a`: numeric and
--   length windows must nest, `multiple_of` divisors must divide,
--   `one_of` sets must be subsets, `pattern`s and `predicate`s must be
--   identical (neither regex nor arbitrary-function containment is
--   decidable), table `properties` recurse with width subtyping (`a`
--   may add fields), and a union-typed schema's `type_schemas` recurse
--   per member. Sound-leaning: an unprovable case is false, so a field
--   `b` constrains that `a` leaves unspecified relates only when `b`'s
--   constraint forbids nothing. Against a bare type a schema erases
--   (every value of `Schema{type = T, ...}` is a `T`) and the reverse
--   holds only for a schema that constrains nothing; against a string
--   type name a schema keeps the `__name` comparison, since a string
--   carries no structure. Every rule mirrors the value level, so a
--   constraint the declared type's `__validate` never reads (a
--   `minimum` on a Union-typed schema, `properties` on a List-typed
--   one, `prefix_items` with no `items`, a `required` name with no
--   `properties` entry) is dead and is credited to neither side, and a
--   schema with no `type` -- which `check_field` raises on, so it
--   accepts nothing -- is undecidable rather than a top type. A plain
--   `{type = ..., <constraints>}` definition table counts as a schema
--   at any depth, exactly as `check_field` accepts one. The structural
--   verdict is final -- without it every untitled schema (all named
--   `'Schema'`) would relate to every other through the name fallback
--   below.
-- - `Lazy`: deferred references are forced (resolving and caching
--   the underlying matcher) before comparison, so a Lazy compares
--   exactly as the matcher it resolves to.
-- - `TypeVar`: outside a signature comparison a type variable is a
--   subtype only of itself and of `Any`; every other comparison
--   involving a TypeVar is false. The structural rules above reach
--   through containers, so containers parameterized by distinct
--   TypeVars are related only where the identity rule allows.
--   Inside a `signature_compatible` check (including the Callable
--   rule above), the candidate signature's variables unify against
--   their concrete counterparts instead -- see the generic
--   signatures section of `signature_compatible` below.
--
-- Caveats: matchers with no structural rule (Iterator, Generator,
-- Protocol, NewType, ClassOf, ...) still compare by non-anonymous
-- `__name` equality -- by design for separately constructed
-- matchers, which carry no identity -- so distinct same-named
-- element types are still conflated one level up inside *those*
-- matchers' names. llx classes themselves carry identity, so the
-- name fallback never applies when either side is a class: two
-- distinct classes sharing a `__name` are unrelated. String type
-- names participate in name equality only -- a string cannot be
-- resolved to a type, so it gets neither the class-hierarchy walk
-- nor numeric widening on the subtype side.
--
-- A comparison whose outcome depends on itself raises an error
-- instead of recursing without bound. That happens when a type
-- contains itself as a direct member through Lazy (e.g. a Lazy
-- union containing only itself) and the comparison reaches that
-- member; every such comparison previously overflowed the stack.
-- The structural rules recurse into container element types, so
-- comparing two *separately constructed* recursive containers is
-- self-dependent and raises too; compare recursive types by
-- identity (the same matcher object on both sides) rather than by
-- structure. Reflexive comparisons of a recursive type with itself
-- are decided by identity before any element walk, so they are
-- unaffected.
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
-- Generic signatures (llx.types.matchers.TypeVar): TypeVars declared
-- by `sub` -- reachable through its params/returns, including nested
-- inside the structurally compared matchers (Union, Tuple, ListOf,
-- SetOf, Dict, Callable) -- are treated as universally quantified
-- over the declared comparison and solved by unification: the
-- variable's first comparison against a counterpart (in check
-- order: parameters left to right, then returns) instantiates it,
-- and every later occurrence resolves to that instantiation and is
-- checked with its own position's variance. The whole check
-- therefore succeeds only if substituting the recorded
-- instantiations satisfies every position, so
--
--   {params = {ListOf(T)}, returns = {T}}
--
-- is compatible with `{params = {ListOf(Integer)}, returns =
-- {Integer}}` (the parameter comparison instantiates T := Integer;
-- the return comparison then checks Integer against Integer).
-- Deliberate, documented choices:
--
-- - One instantiation per declared comparison: nested Callables
--   share the enclosing signature pair's instantiations, while each
--   declaration of a top-level Overload (on either side) is a
--   separate comparison with instantiations of its own -- a generic
--   sub may instantiate differently against each declaration of an
--   overloaded super. generator_compatible likewise spans its whole
--   three-list contract with a single instantiation.
-- - A variable with a `bound` only instantiates to a type B with
--   is_subtype(B, bound); this is conservative for structural
--   bounds (Protocol compares by name at the type level).
-- - Only `sub`'s variables unify. A TypeVar promised by `super` is
--   a promise to work for *every* binding, which no single
--   instantiation can witness, so it keeps the identity-only rule
--   (a concrete signature is never compatible with a generic one),
--   *wherever* it occurs -- including nested under contravariant
--   positions, where the variance flip makes super's Callable the
--   nested candidate: quantification belongs to the outermost
--   signature pair, mypy's whole-signature reading, so
--   {params = {Callable({Integer}, {Integer})}} is not compatible
--   with {params = {Callable({U}, {U})}} even though
--   is_subtype(Callable({U}, {U}), Callable({Integer}, {Integer}))
--   holds when that Callable pair *is* the outermost comparison
--   (there U is the candidate's own variable). A variable occurring
--   on *both* sides never unifies either (instantiating it would
--   let super's universal promise capture sub's instantiation);
--   compare signatures renamed apart where that matters. An unbound
--   sub-only variable may instantiate to a super variable, though,
--   so alpha-equivalent generic signatures are compatible.
-- - Greedy solving: the instantiation is fixed at the first
--   occurrence rather than solved over all constraints at once, so
--   e.g. params={T, T} against super params={Number, Integer}
--   instantiates T := Number and accepts (Integer is a subtype of
--   Number contravariantly at the second position), while
--   {Integer, Number} instantiates T := Integer and rejects. This
--   is sound (never accepts what a full solver would refuse) but
--   incomplete.
-- - The relation is over *declared* types, with mypy's
--   universal-quantification reading of a generic callable. The
--   runtime witness protocol (llx.types.matchers.TypeVar) is
--   deliberately narrower in ways a type-level relation cannot see:
--   it binds from the first *value*, inferred narrowly, so e.g. a
--   params={T, T} function rejects (1, 1.5) at call time even
--   though this relation accepts the signature against
--   {Number, Number}; and a call that never witnesses the variable
--   (an empty list against ListOf(T)) leaves later positions
--   unconstrained at run time. Where the two disagree, this
--   relation follows the declared reading, like the rest of
--   is_subtype.
--
-- Parameter-list variables (llx.types.matchers.ParamSpec): a
-- ParamSpec stands *in place of* a whole parameter list
-- (Callable(P, {R})), capturing "the same parameters as some other
-- signature" so forwarding wrappers can be typed. It unifies by
-- exactly the TypeVar rules, one level up -- against a whole list
-- instead of a single type:
--
-- - A candidate-side ParamSpec instantiates to its counterpart's
--   entire declared parameter list on first occurrence -- including
--   that list's trailing VARARG tail or AnyParams-ness, captured
--   verbatim -- and every later occurrence substitutes it before the
--   arity/variance checks. The canonical decorator shape
--   Callable({Callable(P, {T})}, {Callable(P, {T})}) is therefore
--   compatible with the concrete
--   Callable({Callable({Integer}, {String})},
--            {Callable({Integer}, {String})}) (the contravariant
--   inner position instantiates P := {Integer} and T := String; the
--   covariant inner position substitutes them).
-- - Only `sub`'s ParamSpecs unify; a super-side (or shared) ParamSpec
--   stays universal and is compatible only with the identical
--   ParamSpec object, so a concrete wrapper is not compatible with a
--   generic one, exactly as for a super-side TypeVar. A ParamSpec
--   occurring on both sides is excluded from unification (with an
--   occurs check as backstop).
-- - A ParamSpec replaces the *entire* list; it never co-occurs with
--   leading fixed parameters (mypy's Concatenate is a future
--   extension), and P.args/P.kwargs projection is out of scope. The
--   captured-list boundary (a trailing VARARG tail) is where a future
--   TypeVarTuple/Unpack analog (#104) would compose.
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
  return signature_compatible_impl(sub, super, {})
end

-- The variance rules applied to one plain signature pair (no
-- Overload on either side), factored out of signature_compatible_impl
-- so the latter can bracket it with the TypeVar unification scope.
local function signature_rules(sub, super, in_progress)
  local unify = in_progress[unify_key]
  -- A ParamSpec that already captured a list is substituted for it
  -- here, so the checks below see the concrete captured shape.
  local sub_params = resolve_param_spec(sub.params or {}, unify)
  local super_params = resolve_param_spec(super.params or {}, unify)
  local sub_returns = sub.returns or {}
  local super_returns = super.returns or {}
  -- AnyParams is only meaningful in place of a *parameter* list; a
  -- return list "declared" as AnyParams is malformed, so it is
  -- compatible with nothing (Callable rejects the spelling at
  -- construction; this guards plain contract tables).
  if is_any_params(sub_returns) or is_any_params(super_returns) then
    return false
  end
  -- A ParamSpec still standing in for a whole parameter list (after
  -- any *bound* ParamSpec was substituted above) is unified now: a
  -- candidate-side ParamSpec captures its counterpart's whole list, a
  -- super-side one stays universal (see param_spec_compatible). Once
  -- handled, the per-position parameter arity/variance checks below
  -- are skipped; returns are still compared.
  local params_spec =
      is_param_spec(sub_params) or is_param_spec(super_params)
  local params_concat =
      is_concatenate(sub_params) or is_concatenate(super_params)
  if (params_spec or params_concat)
      and not param_spec_compatible(sub_params, super_params, in_progress)
  then
    return false
  end
  local params_any =
      is_any_params(sub_params) or is_any_params(super_params)
  -- Variadic-generic parameter lists (llx.types.matchers.Unpack): a
  -- top-level Unpack(Ts) in either list splices a bound sequence into
  -- it. Any already-captured Ts is substituted first; if an Unpack
  -- still remains, the candidate-side Unpack captures its
  -- counterpart's spanned region (contravariantly: the pointwise
  -- relation is is_subtype(super, sub)), and the per-position
  -- parameter arity/variance checks below are skipped. When
  -- substitution expanded every Unpack away, the substituted lists
  -- flow into the normal path. Handled before returns so a captured Ts
  -- is available to substitute into the return positions.
  local params_unpack = false
  if not params_any and not params_spec
      and (list_contains_unpack(sub_params)
           or list_contains_unpack(super_params)) then
    sub_params = substitute_unpack(sub_params, unify)
    super_params = substitute_unpack(super_params, unify)
    if find_unpack(sub_params) ~= nil
        or find_unpack(super_params) ~= nil then
      if not unpack_lists_compatible(super_params, sub_params,
                                     in_progress) then
        return false
      end
      params_unpack = true
    end
  end
  local sub_params_fixed, sub_params_variadic
  if not is_any_params(sub_params) and not is_param_spec(sub_params)
      and not params_unpack then
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
  if not is_any_params(super_params)
      and not is_param_spec(super_params) and not params_unpack then
    super_params_fixed, super_params_variadic =
        split_variadic(super_params)
    if super_params_fixed == nil then
      return false
    end
  end
  -- Variadic-generic return lists follow the same pattern, covariantly
  -- (pointwise is_subtype(sub, super)), after params so a Ts captured
  -- from the parameters substitutes into the returns.
  local returns_unpack = false
  if list_contains_unpack(sub_returns)
      or list_contains_unpack(super_returns) then
    sub_returns = substitute_unpack(sub_returns, unify)
    super_returns = substitute_unpack(super_returns, unify)
    if find_unpack(sub_returns) ~= nil
        or find_unpack(super_returns) ~= nil then
      if not unpack_lists_compatible(sub_returns, super_returns,
                                     in_progress) then
        return false
      end
      returns_unpack = true
    end
  end
  local sub_returns_fixed, sub_returns_variadic
  local super_returns_fixed, super_returns_variadic
  if not returns_unpack then
    sub_returns_fixed, sub_returns_variadic =
        split_variadic(sub_returns)
    super_returns_fixed, super_returns_variadic =
        split_variadic(super_returns)
    if sub_returns_fixed == nil or super_returns_fixed == nil then
      return false
    end
  end
  if not params_any and not params_spec and not params_unpack then
    -- Parameter arity. A variadic super promises callers may pass
    -- arbitrary extra arguments, which only a variadic sub accepts
    -- at call time. A variadic sub is fine anywhere its checked
    -- prefix does not extend past super's parameter list. When
    -- either side declares AnyParams or a ParamSpec the parameter
    -- checks are skipped entirely (see the AnyParams/ParamSpec notes
    -- above): only returns are compared.
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
  if not returns_unpack then
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
  end
  -- Parameters are contravariant over the positions sub checks; any
  -- super parameters beyond them land in sub's unchecked tail.
  if not params_any and not params_spec and not params_unpack then
    for i = 1, sub_params_fixed do
      if not is_subtype_impl(super_params[i], sub_params[i],
                             in_progress) then
        return false
      end
    end
  end
  -- Returns are covariant over the positions super promises; any sub
  -- returns beyond them land in super's unchecked tail.
  if not returns_unpack then
    for i = 1, super_returns_fixed do
      if not is_subtype_impl(sub_returns[i], super_returns[i],
                             in_progress) then
        return false
      end
    end
  end
  return true
end

-- The relation proper, with the cycle-guard bookkeeping threaded
-- through every nested type comparison: the public entry point
-- above starts a fresh top-level table, while is_subtype's Callable
-- rule passes its own in-progress table through, so a comparison
-- routed into recursive Callables trips the guard (raising the
-- clear cyclic-comparison error) instead of recursing without
-- bound.
--
-- Overload sets are unfolded first, then each plain signature pair
-- is decided by signature_rules under a TypeVar unification scope.
-- The scope opens at the *outermost* plain pair the comparison
-- reaches and covers everything nested inside it -- Callables inside
-- parameter or return positions reuse it, so one instantiation
-- spans the whole declared signature -- while each top-level
-- overload alternative gets a scope (and therefore an
-- instantiation) of its own: a generic declaration may instantiate
-- differently against each declaration of an overloaded super, as a
-- universally quantified signature may. A failed generic overload
-- alternative under an *active* outer scope rolls its
-- instantiations back before the next alternative is tried.
function signature_compatible_impl(sub, super, in_progress)
  if type(sub) ~= 'table' or type(super) ~= 'table' then
    return false
  end
  local super_overloads = overload_members(super)
  if super_overloads then
    for _, declaration in ipairs(super_overloads) do
      if not signature_compatible_impl(sub, declaration, in_progress)
      then
        return false
      end
    end
    return true
  end
  local sub_overloads = overload_members(sub)
  if sub_overloads then
    for _, declaration in ipairs(sub_overloads) do
      -- Defensive: the savepoint is live only when an overload set
      -- is compared under an already-active scope (a top-level
      -- overloaded sub sees no scope yet, so each declaration's
      -- leaf opens and discards its own).
      local savepoint = unify_savepoint(in_progress)
      if signature_compatible_impl(declaration, super, in_progress)
      then
        return true
      end
      unify_rollback(in_progress, savepoint)
    end
    return false
  end
  if in_progress[unify_key] ~= nil then
    return signature_rules(sub, super, in_progress)
  end
  -- Outermost plain pair: open the unification scope -- even when
  -- there is nothing to unify -- so every signature pair nested
  -- inside this comparison is governed by *this* pair's
  -- quantification instead of opening a scope of its own. In
  -- particular, a generic Callable in super's *parameter* position
  -- becomes the nested candidate under the contravariant flip; its
  -- variables belong to super's declaration, so they must stay
  -- universal here, which the (possibly empty) active scope
  -- enforces uniformly. Variables that also occur on the super
  -- side are excluded from unification: instantiating one would
  -- let sub's instantiation be captured by super's universal
  -- promise, so shared variables keep the identity-only rule
  -- (compare signatures renamed apart where that matters).
  -- ParamSpecs (llx.types.matchers.ParamSpec) that stand in for a
  -- whole parameter list are collected alongside the TypeVars, with
  -- the same super-side exclusion: a candidate-side ParamSpec
  -- captures its counterpart's whole list, a super-side (or shared)
  -- one stays universal. TypeVarTuples reached through Unpack(Ts)
  -- entries (llx.types.matchers.Unpack) are collected the same way --
  -- a candidate-side one captures its counterpart's spanned
  -- sub-sequence, a super-side (or shared) one stays universal. All
  -- three kinds share the log so a speculative branch rolls back any.
  local vars = {}
  local param_specs = {}
  local tvts = {}
  collect_signature_type_vars(sub, vars, param_specs, tvts)
  if next(vars) ~= nil or next(param_specs) ~= nil
      or next(tvts) ~= nil then
    local super_vars = {}
    local super_specs = {}
    local super_tvts = {}
    collect_signature_type_vars(super, super_vars, super_specs,
                                super_tvts)
    for var in pairs(super_vars) do
      vars[var] = nil
    end
    for ps in pairs(super_specs) do
      param_specs[ps] = nil
    end
    for tvt in pairs(super_tvts) do
      tvts[tvt] = nil
    end
  end
  in_progress[unify_key] = {
    unifiable = vars, bindings = {}, log = {},
    unifiable_params = param_specs, param_bindings = {},
    unifiable_tuples = tvts, tuple_bindings = {},
  }
  local compatible = signature_rules(sub, super, in_progress)
  in_progress[unify_key] = nil
  return compatible
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
  -- returns/params variance, so reuse the signature relation for
  -- that pair, and once more for the completion returns. The two
  -- checks share one bookkeeping table and one TypeVar unification
  -- scope spanning the whole three-list contract: a variable used
  -- across yields/accepts *and* returns must resolve to a single
  -- instantiation, exactly as one signature's params and returns
  -- must. The scope is opened here -- over both halves' variables,
  -- with the same super-side exclusion as
  -- signature_compatible_impl -- so the two nested pairs reuse it
  -- instead of instantiating independently.
  local step_sub = {params = sub.accepts or {},
                    returns = sub.yields or {}}
  local step_super = {params = super.accepts or {},
                      returns = super.yields or {}}
  local completion_sub = {returns = sub.returns or {}}
  local completion_super = {returns = super.returns or {}}
  local vars = {}
  local param_specs = {}
  local tvts = {}
  collect_signature_type_vars(step_sub, vars, param_specs, tvts)
  collect_signature_type_vars(completion_sub, vars, param_specs, tvts)
  if next(vars) ~= nil or next(param_specs) ~= nil
      or next(tvts) ~= nil then
    local super_vars = {}
    local super_specs = {}
    local super_tvts = {}
    collect_signature_type_vars(step_super, super_vars, super_specs,
                                super_tvts)
    collect_signature_type_vars(completion_super, super_vars,
                                super_specs, super_tvts)
    for var in pairs(super_vars) do
      vars[var] = nil
    end
    for ps in pairs(super_specs) do
      param_specs[ps] = nil
    end
    for tvt in pairs(super_tvts) do
      tvts[tvt] = nil
    end
  end
  local in_progress = {
    [unify_key] = {
      unifiable = vars, bindings = {}, log = {},
      unifiable_params = param_specs, param_bindings = {},
      unifiable_tuples = tvts, tuple_bindings = {},
    },
  }
  return signature_compatible_impl(step_sub, step_super, in_progress)
    and signature_compatible_impl(completion_sub, completion_super,
                                  in_progress)
end

--- Returns true when `value` is a schema for subtyping purposes.
--
-- True for a wrapper built by `llx.schema.Schema` (recognized by the
-- marker on its metatable) and for a plain `{type = ..., <constraints>}`
-- definition table, which `matches_schema` accepts just the same and
-- which nested definitions are routinely written as. Exposed because the
-- marker is deliberately not a key on the schema itself, so callers
-- cannot test for one without this.
--
-- @param value The value to test
-- @return True when `value` would be compared by the schema rules
_ENV.is_schema = is_schema

return _M

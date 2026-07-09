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
local VARARG = check_arguments.VARARG
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
    if a == b then return true end
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

--- Returns true when type `a` is a subtype of type `b`.
--
-- A value of type `a` can safely be used wherever a value of type `b`
-- is expected. The relation is reflexive and covers:
--
-- - `Any` as the top type: everything is a subtype of `Any`.
-- - `Union`: a union is a subtype of `b` when every member is; `a` is
--   a subtype of a union when it is a subtype of any member.
-- - Numeric widening: `Integer` and `Float` are subtypes of `Number`,
--   mirroring the value level where both satisfy `Number`.
-- - Classes: the transitive `__superclasses` chain is walked, so a
--   derived class is a subtype of each of its bases.
-- - `Lazy`: deferred references are forced (resolving and caching
--   the underlying matcher) before comparison, so a Lazy compares
--   exactly as the matcher it resolves to.
--
-- Caveats: distinct types sharing a non-anonymous `__name` compare as
-- equal (and therefore as mutual subtypes), matching the equality
-- rule used for signature matching. String type names participate in
-- name equality only -- a string cannot be resolved to a type, so it
-- gets neither the class-hierarchy walk nor numeric widening on the
-- subtype side.
--
-- @param a The candidate subtype (a type matcher, class, or name)
-- @param b The candidate supertype (a type matcher, class, or name)
-- @return True if `a` is a subtype of `b`, otherwise false
function is_subtype(a, b)
  if a == nil or b == nil then
    return false
  end
  -- Lazy matchers are forced up front (llx.types.matchers.Lazy;
  -- forcing caches the resolution), so the whole relation -- name
  -- equality, union member walks, numeric widening, superclass
  -- chains -- sees the resolved matchers. Nested Lazy members are
  -- forced by the recursive is_subtype calls below.
  a = resolve_lazy(a)
  b = resolve_lazy(b)
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
      if not is_subtype(member, b) then
        return false
      end
    end
    return true
  end
  -- a is a subtype of a union when it is a subtype of any member.
  local b_members = union_members(b)
  if b_members then
    for _, member in ipairs(b_members) do
      if is_subtype(a, member) then
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
        if is_subtype(superclass, b) then
          return true
        end
      end
    end
  end
  return false
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
-- satisfies it. An unchecked-parameters escape hatch is a separate
-- feature.
--
-- A non-trailing VARARG makes a signature malformed (its call-time
-- check raises unconditionally), so it is compatible with nothing.
--
-- @param sub The candidate signature (used where `super` is expected)
-- @param super The required signature
-- @return True if `sub` is compatible with `super`, otherwise false
function signature_compatible(sub, super)
  if type(sub) ~= 'table' or type(super) ~= 'table' then
    return false
  end
  local sub_params = sub.params or {}
  local super_params = super.params or {}
  local sub_returns = sub.returns or {}
  local super_returns = super.returns or {}
  local sub_params_fixed, sub_params_variadic =
      split_variadic(sub_params)
  local super_params_fixed, super_params_variadic =
      split_variadic(super_params)
  local sub_returns_fixed, sub_returns_variadic =
      split_variadic(sub_returns)
  local super_returns_fixed, super_returns_variadic =
      split_variadic(super_returns)
  if sub_params_fixed == nil or super_params_fixed == nil
      or sub_returns_fixed == nil or super_returns_fixed == nil then
    return false
  end
  -- Parameter arity. A variadic super promises callers may pass
  -- arbitrary extra arguments, which only a variadic sub accepts at
  -- call time. A variadic sub is fine anywhere its checked prefix
  -- does not extend past super's parameter list.
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
  -- Return arity is the mirror image: a variadic sub may produce
  -- undeclared extras that a fixed super's callers would observe,
  -- and a variadic super's fixed prefix must be covered by sub's
  -- declared returns.
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
  for i = 1, sub_params_fixed do
    if not is_subtype(super_params[i], sub_params[i]) then
      return false
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

return _M

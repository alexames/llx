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

local environment = require 'llx.environment'
local matchers = require 'llx.types.matchers'

local Float = require 'llx.types.float' . Float
local Integer = require 'llx.types.integer' . Integer
local Number = require 'llx.types.number' . Number

local Any = matchers.Any

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

--- Returns true when signature `sub` can be used where `super` is
--- expected.
--
-- Both arguments are tables carrying `params` and `returns` arrays of
-- type matchers -- Signature-wrapped functions, Callable matchers, or
-- plain `{params = {...}, returns = {...}}` tables. Missing lists
-- default to empty.
--
-- Variance rules (the relation mypy applies to Callable):
--
-- - Parameters are contravariant: each of `super`'s parameter types
--   must be a subtype of the corresponding `sub` parameter type, so
--   `sub` accepts at least everything `super` promises to accept.
-- - Returns are covariant: each of `sub`'s return types must be a
--   subtype of the corresponding `super` return type.
--
-- Arity must match exactly on both sides. For parameters this is the
-- conservative starting rule (varargs and optional trailing
-- parameters are not modeled). For returns it is required for
-- soundness: a Lua call in the tail of an expression list expands all
-- of its results, so extra return values are observable at call
-- sites.
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
  if #sub_params ~= #super_params then
    return false
  end
  local sub_returns = sub.returns or {}
  local super_returns = super.returns or {}
  if #sub_returns ~= #super_returns then
    return false
  end
  -- Parameters are contravariant.
  for i = 1, #super_params do
    if not is_subtype(super_params[i], sub_params[i]) then
      return false
    end
  end
  -- Returns are covariant.
  for i = 1, #sub_returns do
    if not is_subtype(sub_returns[i], super_returns[i]) then
      return false
    end
  end
  return true
end

return _M

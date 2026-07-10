-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx.core'
local environment = require 'llx.environment'

-- Load-bearing: TypeVar binding inference binds numbers to the
-- narrowest of these singletons (see infer_type_var_binding).
local Float = require 'llx.types.float' . Float
local Integer = require 'llx.types.integer' . Integer

local Nil = require 'llx.types.nil' . Nil
local Number = require 'llx.types.number' . Number
local Set = require 'llx.types.set' . Set
local Table = require 'llx.types.table' . Table
local isinstance = require 'llx.isinstance' . isinstance

local is_callable = core.is_callable

local _ENV, _M = environment.create_module_environment()

local function type_name_of(t)
  -- String type names (and the VARARG '...' marker) are their own
  -- description. The explicit type check matters: llx extends the
  -- string library, so every Lua string exposes __name == 'String'
  -- and the generic branch would render all of them as 'String' --
  -- which would also make matcher names collide (e.g.
  -- Callable({VARARG}, {}) with Callable({String}, {})), and
  -- is_subtype falls back to name equality when comparing matchers.
  if type(t) == 'string' then
    return t
  end
  return t and (t.__name or tostring(t)) or 'nil'
end

-- The stack of active TypeVar binding scopes. A scope is a plain
-- table mapping TypeVar objects (by identity, never by name) to the
-- type they bound in the current checked call; the innermost entry is
-- the active scope. The stack is entered and exited only around
-- synchronous signature checks (llx.signature pushes before checking
-- a call's arguments or returns and pops immediately after, whether
-- or not the check raises), never across user code:
--
-- - Recursion nests naturally: an inner wrapped call pushes its own
--   scope on top and pops it before the outer check resumes.
-- - Coroutines are safe: the wrapped function's *body* runs with no
--   scope active, so a yield never suspends midway through an entered
--   scope, and interleaved coroutines cannot observe each other's
--   bindings.
--
-- This dynamic-scope design is what lets parameterized matchers
-- (ListOf(T), Dict(K, V), Tuple, ...) propagate bindings into element
-- checks with no change to the __isinstance protocol: their recursive
-- isinstance calls reach TypeVar.__isinstance, which reads the
-- innermost scope here.
local type_var_scope_stack = {}

-- Opens a TypeVar binding scope: pushes `scope` (a fresh table when
-- nil) and returns it. Primarily an integration hook for
-- llx.signature, which opens a scope around a call's precondition
-- check and re-enters the same scope around the postcondition check
-- so parameters and returns share one set of bindings. Every enter
-- must be paired with exit_type_var_scope, including on error paths.
local function enter_type_var_scope(scope)
  if scope == nil then
    scope = {}
  elseif type(scope) ~= 'table' then
    error('enter_type_var_scope: expected a scope table (or nil), '
      .. 'got ' .. type(scope), 2)
  end
  type_var_scope_stack[#type_var_scope_stack + 1] = scope
  return scope
end

-- Closes the innermost TypeVar binding scope (the counterpart of
-- enter_type_var_scope). Raises if no scope is active, since an
-- unbalanced exit indicates a caller bug that would otherwise
-- silently corrupt an enclosing scope.
local function exit_type_var_scope()
  local top = #type_var_scope_stack
  if top == 0 then
    error('exit_type_var_scope: no active TypeVar binding scope', 2)
  end
  type_var_scope_stack[top] = nil
end

-- Private key under which a scope stores the witness sets
-- accumulated by commutative regions (see commutative_mark below):
-- a table mapping each TypeVar to the array of distinct witness
-- types it has seen inside such regions. The join is always computed
-- over the whole set at once, never by folding pairwise -- a
-- pairwise fold is not associative under multiple inheritance (an
-- ambiguous intermediate tie-break can drift to a different, coarser
-- result depending on encounter order), and order-independence is
-- the whole point. A non-string, module-local key keeps the sets out
-- of the scope's TypeVar namespace.
local witnesses_mark = {}

-- Snapshots the innermost TypeVar binding scope so a speculative
-- matcher branch can be rolled back when it fails. Returns nil (a
-- no-op savepoint) when no scope is active -- the common plain
-- isinstance case, which pays nothing. Union.__isinstance is the
-- primary caller: without a savepoint, a union member that binds a
-- TypeVar from part of a value it ultimately rejects would leave the
-- stale binding constraining the rest of the call, making union
-- member order observable. The witness sets are copied one level
-- deeper than the bindings: the branch mutates the inner arrays, so
-- restoring a shared reference would not roll them back.
local function save_type_var_bindings()
  local scope = type_var_scope_stack[#type_var_scope_stack]
  if scope == nil then
    return nil
  end
  local snapshot = {}
  for key, value in pairs(scope) do
    if key == witnesses_mark then
      local witness_sets = {}
      for var, list in pairs(value) do
        local copy = {}
        for i = 1, #list do
          copy[i] = list[i]
        end
        witness_sets[var] = copy
      end
      snapshot[key] = witness_sets
    else
      snapshot[key] = value
    end
  end
  return snapshot
end

-- Restores the innermost scope to a snapshot taken by
-- save_type_var_bindings, discarding bindings recorded (or widened)
-- since. The scope table is mutated in place, never replaced:
-- llx.signature holds a reference to it across the precondition and
-- postcondition checks, so its identity must survive rollbacks. A
-- nil snapshot (no scope was active at save time) is a no-op.
local function restore_type_var_bindings(snapshot)
  if snapshot == nil then
    return
  end
  local scope = type_var_scope_stack[#type_var_scope_stack]
  if scope == nil then
    return
  end
  for var in pairs(scope) do
    if snapshot[var] == nil then
      scope[var] = nil
    end
  end
  for var, binding in pairs(snapshot) do
    scope[var] = binding
  end
end

-- Private key under which a scope records how many commutative
-- witness regions are currently open on it. Inside such a region --
-- entered by matchers whose element iteration order is semantically
-- meaningless (Dict, SetOf, which iterate with pairs) -- TypeVar
-- consistency is symmetric: instead of checking a later value
-- against the recorded binding, the binding is widened to the join
-- (least common supertype) of itself and the value's inferred type,
-- and the check fails only when no join exists. The join is
-- computed over the variable's whole accumulated witness set (see
-- witnesses_mark above and join_witness_set below), which is
-- symmetric, so the container's verdict and the resulting binding
-- are independent of the order pairs happens to produce. A
-- non-string, module-local key keeps the counter out of the scope's
-- TypeVar namespace.
local commutative_mark = {}

-- Opens a commutative witness region on the innermost scope and
-- returns that scope (nil when no scope is active, in which case
-- nothing was opened and the matching end call is a no-op). The
-- returned scope must be passed back to end_commutative_witnesses so
-- the counter lands on the same table even if scopes were pushed or
-- popped in between.
local function begin_commutative_witnesses()
  local scope = type_var_scope_stack[#type_var_scope_stack]
  if scope == nil then
    return nil
  end
  scope[commutative_mark] = (scope[commutative_mark] or 0) + 1
  return scope
end

-- Closes a commutative witness region opened by
-- begin_commutative_witnesses on `scope` (a no-op when nil).
local function end_commutative_witnesses(scope)
  if scope == nil then
    return
  end
  local depth = scope[commutative_mark]
  if depth ~= nil then
    scope[commutative_mark] = depth > 1 and depth - 1 or nil
  end
end

local function any_type_check()
  return setmetatable({
    __name = 'Any';

    __isinstance = function(self, value)
      return true
    end;
  }, {
    __tostring = function() return 'Any' end;
  })
end

local function never_type_check()
  -- The bottom type: no value is an instance of Never. It is the
  -- counterpart of Any (the top type), useful for exhaustiveness
  -- assertions (a branch that should be unreachable can check its
  -- value against Never to fail loudly) and as the identity element
  -- when composing unions programmatically.
  return setmetatable({
    __name = 'Never';

    __isinstance = function(self, value)
      return false
    end;
  }, {
    __tostring = function() return 'Never' end;
  })
end

-- Forward declarations: raise ValueException when a declared type
-- position (or any entry of a declared type list) holds a stray
-- Rest(T) or AnyParams marker. Defined with the marker machinery
-- below; declared here so the composite matcher constructors above
-- that machinery can reject markers in their element types.
local reject_markers
local reject_marker_entries

-- Marker key under which a parameterized container matcher records
-- its kind ('ListOf', 'SetOf', 'Dict', or 'Callable'). llx.is_subtype
-- needs to tell the kinds apart to apply the right structural rule,
-- and the introspection fields alone cannot always do it (ListOf and
-- SetOf both expose exactly element_type). A module-local table key
-- cannot be forged (or observed) outside this module, so nothing
-- else can accidentally look like one of these matchers;
-- matcher_kind (exported below) is the public way to read the kind.
local matcher_kind_mark = {}

-- Returns the container kind of a parameterized matcher built by
-- this module ('ListOf', 'SetOf', 'Dict', or 'Callable'), or nil for
-- everything else. Tuples and unions are recognized by their
-- introspection fields instead (element_types/fixed_count and
-- type_list, which are unambiguous), so they carry no mark.
local function matcher_kind(value)
  if type(value) == 'table' then
    return rawget(value, matcher_kind_mark)
  end
  return nil
end

-- Bookkeeping for the union member walk below: maps each union
-- matcher currently checking a value to the set of values it is
-- checking (see union_type_check). Entries are removed on the way
-- out -- including on error, via pcall -- so the table is empty
-- between top-level isinstance calls. Unlike is_subtype's per-call
-- guard table this state is module-level (the __isinstance protocol
-- has nowhere to thread a parameter through), so its marks span the
-- member matcher calls; a member matcher that yielded across
-- coroutines mid-check could therefore interleave two checks of
-- the same pair, but matchers are synchronous by convention (the
-- TypeVar scope stack above relies on the same property).
local active_union_checks = {}

-- nil and NaN cannot be table keys, so sentinels stand in for them
-- in the per-union visited sets. All NaNs share one sentinel, which
-- can only ever conflate values that already compare unequal to
-- themselves.
local nil_value_key = {}
local nan_value_key = {}

local function union_value_key(value)
  if value == nil then
    return nil_value_key
  end
  if value ~= value then
    return nan_value_key
  end
  return value
end

local function union_type_check(type_list)
  reject_marker_entries(type_list, 'Union')
  local expected_typenames = '{' .. Table.concat(type_list, ',') .. '}'
  local typename = 'Union' .. expected_typenames

  local function members_match(value)
    -- Each member is a speculative branch: a member that binds a
    -- TypeVar from part of the value and then rejects it must not
    -- leave that stale binding constraining the rest of the call
    -- (which would make union member order observable). The
    -- savepoint rolls the innermost binding scope back after every
    -- failed branch; a successful branch keeps its bindings, as
    -- usual for first-match-wins dispatch. With no active scope
    -- the savepoint is nil and costs nothing.
    for _, type_checker in ipairs(type_list) do
      local savepoint = save_type_var_bindings()
      if isinstance(value, type_checker) then
        return true
      end
      restore_type_var_bindings(savepoint)
    end
    return false
  end

  return setmetatable({
    __name = typename,

    type_list = type_list,

    __isinstance = function(self, value)
      -- Cycle guard, the isinstance analog of is_subtype's
      -- pair-based occurs check: a degenerate self-referential union
      -- (one whose member walk reaches this same union again through
      -- Lazy -- or through a container member holding the value
      -- itself) re-enters this check with the same (union, value)
      -- pair, so its outcome would depend on itself. Re-entering can
      -- never produce new information, so it raises a clear error
      -- instead of recursing without bound. Recursion that descends
      -- into *parts* of the value (a JSON-style union over ListOf
      -- and Dict members) checks different values against this
      -- union, so it never trips the guard. The pair is unmarked on
      -- the way out -- via pcall, so an error raised by a member
      -- matcher cannot leak marks into later checks.
      local seen = active_union_checks[self]
      local key = union_value_key(value)
      if seen ~= nil and seen[key] then
        error('isinstance: cyclic type check: deciding whether a '
          .. 'value is an instance of ' .. tostring(self)
          .. ' depends on itself (a recursive type that contains '
          .. 'itself as a direct member?)', 0)
      end
      if seen == nil then
        seen = {}
        active_union_checks[self] = seen
      end
      seen[key] = true
      local ok, result = pcall(members_match, value)
      seen[key] = nil
      if next(seen) == nil then
        active_union_checks[self] = nil
      end
      if not ok then
        error(result, 0)
      end
      return result
    end,

    __validate = function(self, schema, path, level, check_field)
      local type_schemas = schema.type_schemas
      local getclass = require 'llx.getclass' . getclass
      local cls = getclass(self)
      local type_schema = type_schemas and type_schemas[cls.__name or cls]
      if type_schema then
        return check_field(type_schema, self, path, level + 1)
      end
      return true
    end,
  }, {
    __tostring = function(self)
      return self.__name
    end,
  })
end

local function optional_type_check(type_or_list)
  -- Accept both Optional(Type) (natural form) and Optional{Type}
  -- (list-wrapped form, consistent with Union's calling convention).
  -- Distinguish by presence of __isinstance: a real type checker
  -- always has it; a bare list wrapper does not.
  --
  -- A bare marker must be rejected before the list-unwrap test:
  -- neither Rest(T) nor AnyParams carries __isinstance, so
  -- Optional(Rest(T)) would otherwise be mistaken for the
  -- list-wrapped form and silently collapse to Union{Nil, nil}. The
  -- list-wrapped form is checked entry-wise -- extra entries are
  -- ignored by the unwrap, but a marker among them is still a
  -- mistake, and Union{...} of the same list would reject it. Both
  -- checks name Optional (the actual construction site) rather than
  -- the Union built below.
  reject_markers(type_or_list, 'Optional')
  local inner = type_or_list
  if type(type_or_list) == 'table'
      and type_or_list.__isinstance == nil then
    reject_marker_entries(type_or_list, 'Optional')
    inner = type_or_list[1]
  end
  return union_type_check{Nil, inner}
end

local function protocol_type_check(fields)
  if type(fields) ~= 'table' then
    error('Protocol: expected a table of {name = type}', 3)
  end
  -- Optional fields: absent and nil are indistinguishable in Lua, so
  -- declaring a field as Optional(T) is the optional-field mechanism
  -- (Python's NotRequired[T] collapses to Optional here). The check
  -- below passes whether the key is missing or holds a T.
  --
  -- The __exact metafield closes the shape (TypedDict-style): in
  -- exact mode the value may carry only declared fields, so unknown
  -- (e.g. typo'd) keys are rejected. The __ prefix keeps the flag out
  -- of the field namespace, matching metafield conventions.
  local exact = fields.__exact
  if exact ~= nil and type(exact) ~= 'boolean' then
    -- A truthy non-boolean would otherwise be silently treated as
    -- one mode or the other; fail loudly instead.
    error('Protocol: __exact must be a boolean', 3)
  end
  exact = exact == true
  -- Copy the declared fields, excluding the __exact flag, so the
  -- exposed shape and the checks below see only real fields. A field
  -- typed with a stray Rest(T)/AnyParams marker would be silently
  -- unsatisfiable (neither carries __isinstance), so it is rejected
  -- at construction like any other composite type position.
  local declared = {}
  for k, v in pairs(fields) do
    if k ~= '__exact' then
      reject_markers(v, 'Protocol')
      declared[k] = v
    end
  end
  -- Capture field names for the type name; sort for stability.
  local field_names = {}
  for k in pairs(declared) do field_names[#field_names + 1] = k end
  table.sort(field_names, function(a, b)
    return tostring(a) < tostring(b)
  end)
  -- Exactness is part of the matcher's identity, so it is encoded in
  -- the name (which is_subtype falls back to when comparing matchers).
  local typename = 'Protocol{' .. table.concat(field_names, ', ') .. '}'
                   .. (exact and ' exact' or '')
  return setmetatable({
    __name = typename,

    -- Expose the shape so callers can introspect.
    fields = declared,
    exact = exact,

    __isinstance = function(self, value)
      if type(value) ~= 'table' then return false end
      for field_name, expected_type in pairs(declared) do
        if not isinstance(value[field_name], expected_type) then
          return false
        end
      end
      if exact then
        -- Closed shape: reject any key outside the declared field
        -- set. Only raw keys are examined (iterating with next
        -- bypasses __pairs and __index), so metatable-provided
        -- fields do not count against the shape.
        for key in next, value do
          if declared[key] == nil then
            return false
          end
        end
      end
      return true
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

local function dict_type_check(key_type, value_type)
  reject_markers(key_type, 'Dict')
  reject_markers(value_type, 'Dict')
  local typename = 'Dict<' .. type_name_of(key_type) ..
                   ', ' .. type_name_of(value_type) .. '>'

  local function entries_match(value)
    for k, v in pairs(value) do
      if not isinstance(k, key_type) then return false end
      if not isinstance(v, value_type) then return false end
    end
    return true
  end

  return setmetatable({
    [matcher_kind_mark] = 'Dict',

    __name = typename,

    key_type = key_type,
    value_type = value_type,

    __isinstance = function(self, value)
      if type(value) ~= 'table' then return false end
      -- pairs order is unspecified, so the element checks run in a
      -- commutative witness region: a TypeVar in key_type or
      -- value_type binds the join of all witnesses it sees instead
      -- of whichever element pairs yields first, keeping the verdict
      -- and the binding independent of iteration order. Without an
      -- active binding scope the region is a no-op and the loop runs
      -- unwrapped. The pcall guarantees the region closes even when
      -- a user matcher raises out of the loop.
      local scope = begin_commutative_witnesses()
      if scope == nil then
        return entries_match(value)
      end
      local ok, result = pcall(entries_match, value)
      end_commutative_witnesses(scope)
      if not ok then
        error(result, 0)
      end
      return result
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

local function list_of_type_check(element_type)
  reject_markers(element_type, 'ListOf')
  local typename = 'ListOf<' .. type_name_of(element_type) .. '>'
  return setmetatable({
    [matcher_kind_mark] = 'ListOf',

    __name = typename,

    -- Expose the element type so callers can introspect.
    element_type = element_type,

    __isinstance = function(self, value)
      -- Accept any list-shaped table: plain array tables and
      -- llx.List instances alike (List stores its elements in the
      -- array part, so ipairs works on both). Nominal checking is
      -- already available via isinstance(value, List).
      --
      -- List-shaped means the raw keys are exactly 1..n for the
      -- ipairs-covered prefix: no hash keys, no holes. Without the
      -- shape check the element loop is vacuous over any table with
      -- an empty array part, so {meta = print} would satisfy
      -- ListOf(Integer) (issue #65). The empty table {} is accepted:
      -- an empty list IS {} in Lua, indistinguishable from an empty
      -- dict. Only raw keys are examined (iterating with next
      -- bypasses __pairs and __index, the same policy as Protocol's
      -- exact mode), so metatable-provided fields do not count
      -- against the shape. Like Dict, the check walks every element,
      -- so each isinstance call is O(n) in the length of the list.
      if type(value) ~= 'table' then return false end
      local count = 0
      for _, element in ipairs(value) do
        count = count + 1
        if not isinstance(element, element_type) then
          return false
        end
      end
      for key in next, value do
        if math.type(key) ~= 'integer'
            or key < 1 or key > count then
          return false
        end
      end
      return true
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

local function set_of_type_check(element_type)
  reject_markers(element_type, 'SetOf')
  local typename = 'SetOf<' .. type_name_of(element_type) .. '>'

  local function elements_match(value)
    for element in pairs(value) do
      if not isinstance(element, element_type) then
        return false
      end
    end
    return true
  end

  return setmetatable({
    [matcher_kind_mark] = 'SetOf',

    __name = typename,

    -- Expose the element type so callers can introspect.
    element_type = element_type,

    __isinstance = function(self, value)
      -- Require an actual llx.Set instance; a plain table used as a
      -- raw key-set can already be expressed as Dict(T, Boolean).
      -- The nominal guard also means SetOf never vacuously matches
      -- arbitrary tables the way pre-#65 ListOf did: a non-Set is
      -- rejected before any element iteration. Iterating a Set (via
      -- its __pairs metamethod) yields element -> true, so the
      -- elements are the keys. Like Dict, each isinstance call is
      -- O(n) in the size of the set.
      if not isinstance(value, Set) then return false end
      -- A set is unordered, so the element checks run in a
      -- commutative witness region (see Dict above): a TypeVar in
      -- element_type binds the join of all witnesses, independent of
      -- the order pairs yields the elements.
      local scope = begin_commutative_witnesses()
      if scope == nil then
        return elements_match(value)
      end
      local ok, result = pcall(elements_match, value)
      end_commutative_witnesses(scope)
      if not ok then
        error(result, 0)
      end
      return result
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

-- Marker key identifying Rest(T) typed-tail wrappers, used by Tuple.
-- A module-local table key cannot be forged (or observed) outside
-- this module, so nothing else can accidentally look like a Rest.
-- is_rest (exported below) is the public way to recognize one.
local rest_mark = {}

local function rest_type_check(element_type)
  -- Rest(T): the typed variadic-tail marker for Tuple, the spelling
  -- of mypy's `tuple[T, ...]` tail. Only meaningful as the *last*
  -- entry of a Tuple element type list, where it declares that every
  -- value beyond the fixed prefix must satisfy T. It is not a
  -- standalone matcher (it has no __isinstance), so isinstance
  -- against a bare Rest(T) raises the non-matcher error.
  --
  -- This is deliberately distinct from the bare VARARG ('...')
  -- marker established by llx.check_arguments: VARARG is a plain
  -- string (so it can appear in declared type lists without
  -- colliding with class names) and means "unchecked tail", whereas
  -- Rest(T) checks the tail. Making VARARG callable to support
  -- VARARG(T) would change its type and break the string comparisons
  -- Signature, Callable, and is_subtype rely on.
  -- Falsy values are rejected outright (not just nil): no value can
  -- ever satisfy `false` as a type, and a falsy element_type would
  -- defeat the truthiness tests Tuple applies to the marker.
  if not element_type then
    error('Rest: expected an element type', 2)
  end
  return setmetatable({
    [rest_mark] = true,

    -- Expose the tail element type so callers can introspect.
    element_type = element_type,
  }, {
    __tostring = function(self)
      return '...' .. type_name_of(element_type)
    end,
  })
end

local function is_rest(entry)
  return type(entry) == 'table' and rawget(entry, rest_mark) == true
end

-- Cached upvalue for the deferred require of llx.check_arguments
-- (deferred to avoid a load-time cycle: llx.check_arguments depends,
-- through llx.getclass, on llx.types and therefore on this module).
local check_arguments_module = nil

-- Cached upvalue for the deferred require of llx.exceptions
-- (deferred to avoid load-time cycles; the exception hierarchy is
-- only needed on the construction-error paths below).
local exceptions_module = nil

-- Marker key identifying the AnyParams sentinel below. A
-- module-local table key cannot be forged (or observed) outside this
-- module, so nothing else can accidentally look like AnyParams.
-- is_any_params (exported below) is the public way to recognize it.
local any_params_mark = {}

-- AnyParams: the "any parameters" escape hatch for Callable, the
-- runtime analog of mypy's Callable[..., R]. Passed *in place of*
-- Callable's parameter type list -- Callable(AnyParams, {R}) -- it
-- declares that parameters are not checked at all: every declared
-- parameter list is compatible (see
-- llx.is_subtype.signature_compatible) and every raw function is
-- accepted regardless of arity; only returns are compared.
--
-- This is deliberately distinct from Callable({VARARG}, {R}), which
-- is a *checked* promise that callers may pass arbitrary extras and
-- therefore requires the matched function to itself be variadic.
-- AnyParams, like Any, is gradual rather than sound: a fixed-arity
-- function is accepted even though a caller holding the
-- Callable(AnyParams, ...) view could pass it arguments it never
-- declared. It is not a type matcher (it has no __isinstance), so
-- using it as one raises the standard non-matcher error, and it is
-- only valid as Callable's whole parameter list -- inside a type
-- list, or anywhere in a return list, it is rejected at
-- construction.
local any_params_sentinel = setmetatable({
  [any_params_mark] = true,
}, {
  __tostring = function() return 'AnyParams' end,
})

local function is_any_params(value)
  return type(value) == 'table'
     and rawget(value, any_params_mark) == true
end

-- Marker key identifying ParamSpec sentinels below. A module-local
-- table key cannot be forged (or observed) outside this module, so
-- nothing else can accidentally look like a ParamSpec. is_param_spec
-- (exported below) is the public way to recognize one. The marker and
-- predicate are declared here, above reject_markers, so the composite
-- constructors can reject a stray ParamSpec the same way they reject
-- a stray AnyParams; the ParamSpec factory itself is defined near
-- TypeVar (its sibling generics construct) further down.
local param_spec_mark = {}

local function is_param_spec(value)
  return type(value) == 'table'
     and rawget(value, param_spec_mark) == true
end

-- Raises ValueException when `entry` -- a single declared type
-- position (a Union member, Optional's inner type, a Dict key or
-- value type, a ListOf/SetOf element type, a Protocol field type, or
-- one entry of a signature-shaped type list) -- is a stray Rest(T)
-- or AnyParams marker. Neither marker carries __isinstance, so a
-- type position holding one could never match any value; failing
-- loudly at construction is the same policy Callable applies to a
-- non-trailing VARARG. Rest(T) is only meaningful as the trailing
-- entry of a Tuple element list, and AnyParams only in place of
-- Callable's whole parameter list. `where` names the raising matcher
-- in the message; `level` (default 3, one frame above the caller)
-- anchors the exception's traceback at the constructor's call site.
-- (Declared, with reject_marker_entries, near the top of the module
-- so the composite constructors can see them.)
function reject_markers(entry, where, level)
  level = level or 3
  if is_rest(entry) then
    exceptions_module = exceptions_module or require 'llx.exceptions'
    error(exceptions_module.ValueException(
      where .. ': Rest(T) is only valid inside Tuple; use a '
      .. "trailing VARARG ('...') for variadic signatures", level))
  end
  if is_any_params(entry) then
    exceptions_module = exceptions_module or require 'llx.exceptions'
    error(exceptions_module.ValueException(
      where .. ': AnyParams replaces the whole parameter list '
      .. '(Callable(AnyParams, returns)); it is not valid as a '
      .. 'type list entry', level))
  end
  if is_param_spec(entry) then
    exceptions_module = exceptions_module or require 'llx.exceptions'
    error(exceptions_module.ValueException(
      where .. ': ParamSpec replaces the whole parameter list '
      .. '(Callable(P, returns)); it is not valid as a type list '
      .. 'entry', level))
  end
end

-- Applies reject_markers to every entry of a declared type list
-- (Callable params/returns, Iterator yields, Generator contract
-- lists, Union member lists), keeping the messages uniform across
-- every rejection site. The bumped level skips this extra frame so
-- the traceback still starts at the constructor's call site.
function reject_marker_entries(type_list, where)
  for i = 1, #type_list do
    reject_markers(type_list[i], where, 4)
  end
end

local function callable_type_check(param_types, return_types, options)
  param_types = param_types or {}
  return_types = return_types or {}
  options = options or {}
  local strict = options.strict == true

  -- AnyParams in place of the parameter list is the "do not check
  -- parameters" escape hatch (mypy's Callable[..., R]); see the
  -- sentinel's documentation above. It admits no per-parameter
  -- entries, so the list validation below is skipped wholesale. It
  -- is params-only: a return list cannot be unchecked this way
  -- (declare a trailing VARARG for an unchecked return tail).
  local params_any = is_any_params(param_types)
  -- A ParamSpec (Callable(P, {R})) also stands *in place of* the
  -- whole parameter list, capturing "the same parameters as some
  -- other signature" for the type-level relation (see
  -- llx.is_subtype.signature_compatible). Like AnyParams it admits no
  -- per-parameter entries, so the list validation below is skipped
  -- for it too, and at the value level it is treated as unchecked
  -- parameters (ParamSpec is a type-level-only construct in this
  -- first iteration; see the __isinstance note below).
  local params_spec = is_param_spec(param_types)
  if is_any_params(return_types) then
    exceptions_module = exceptions_module or require 'llx.exceptions'
    error(exceptions_module.ValueException(
      'Callable: AnyParams is only valid in place of the '
      .. 'parameter list; declare a trailing VARARG (\'...\') for '
      .. 'an unchecked return tail', 2))
  end
  -- strict exists to tighten the raw-function arity check against
  -- the declared parameter shape; AnyParams declares no shape, so
  -- the combination would be a silent no-op. Fail loudly instead.
  if params_any and strict then
    error('Callable: strict has no effect with AnyParams (there is '
      .. 'no declared parameter shape to enforce)', 2)
  end
  -- strict tightens the raw-function arity check against a declared
  -- parameter shape; a ParamSpec carries no concrete shape at
  -- construction (it is captured later, at the type level), so the
  -- combination has nothing to enforce. Fail loudly, as for AnyParams.
  if params_spec and strict then
    error('Callable: strict has no effect with a ParamSpec (there '
      .. 'is no declared parameter shape to enforce)', 2)
  end

  -- A trailing VARARG ('...') entry in param_types declares that the
  -- callable accepts arbitrary extra arguments beyond the fixed,
  -- typed prefix, mirroring Signature's call-time semantics (see
  -- llx.check_arguments). Signature-wrapped values are handled by
  -- signature_compatible; the fixed prefix count computed here drives
  -- the raw-function arity checks below. Note that
  -- Callable({VARARG}, {R}) is not mypy's Callable[..., R] ("do not
  -- check parameters"): it requires the matched function to itself
  -- be declared variadic. Callable(AnyParams, {R}) is that escape
  -- hatch.
  check_arguments_module =
      check_arguments_module or require 'llx.check_arguments'
  local vararg_marker = check_arguments_module.VARARG
  local params_fixed = 0
  local params_variadic = false
  if not params_any and not params_spec then
    params_fixed = #param_types
    params_variadic = param_types[params_fixed] == vararg_marker
    if params_variadic then
      params_fixed = params_fixed - 1
    end
    -- A non-trailing VARARG can never be satisfied
    -- (check_returns_exact raises for it at call time), so fail
    -- loudly at construction rather than silently matching nothing.
    for i = 1, params_fixed do
      if param_types[i] == vararg_marker then
        exceptions_module =
            exceptions_module or require 'llx.exceptions'
        error(exceptions_module.ValueException(
          "Callable: VARARG ('...') must be the last entry in "
          .. 'the parameter list', 2))
      end
    end
  end
  for i = 1, #return_types - 1 do
    if return_types[i] == vararg_marker then
      exceptions_module = exceptions_module or require 'llx.exceptions'
      error(exceptions_module.ValueException(
        "Callable: VARARG ('...') must be the last entry in "
        .. 'the return list', 2))
    end
  end
  -- Rest(T) is a Tuple-only marker (it has no __isinstance), so a
  -- parameter or return position holding one is silently
  -- unsatisfiable; reject it anywhere in either list. A *typed*
  -- variadic tail for signatures is a separate feature; the bare
  -- VARARG marker is the supported (unchecked) spelling. AnyParams
  -- and ParamSpec entries are rejected for the same
  -- silently-unsatisfiable reason. A ParamSpec *in place of* the
  -- whole list carries no entries, so its validation is skipped too.
  if not params_any and not params_spec then
    reject_marker_entries(param_types, 'Callable')
  end
  reject_marker_entries(return_types, 'Callable')

  -- The AnyParams parameter list renders as a bare, unparenthesized
  -- '*' -- deliberately distinct from the variadic list's '(...)':
  -- the two forms are different types (one checks that the function
  -- is variadic, the other checks nothing), and while is_subtype
  -- compares two Callables structurally, everything else -- error
  -- messages, Union names, name equality against matchers with no
  -- structural rule -- sees the name. Dropping the parentheses also
  -- makes the spelling unforgeable through entry names: every
  -- concrete parameter list renders inside '(...)', so no list entry
  -- (e.g. the string type name '*') can collide with it.
  -- A ParamSpec parameter list renders as a bare '**Name' -- again
  -- unparenthesized, so it cannot collide with a concrete list (which
  -- always renders inside '(...)') and stays distinct from AnyParams'
  -- '*'. Two distinct ParamSpecs sharing a name render alike, the
  -- same name-collision caveat as TypeVar; is_subtype compares
  -- Callables structurally, so it never relies on this name for
  -- ParamSpec identity.
  local param_list_name
  if params_any then
    param_list_name = '*'
  elseif params_spec then
    param_list_name = '**' .. type_name_of(param_types)
  else
    local param_names = {}
    for i, t in ipairs(param_types) do
      param_names[i] = type_name_of(t)
    end
    param_list_name = '(' .. table.concat(param_names, ', ') .. ')'
  end
  local return_names = {}
  for i, t in ipairs(return_types) do return_names[i] = type_name_of(t) end
  -- Strictness is part of the matcher's identity, so it is encoded
  -- in the name (is_subtype compares Callables structurally --
  -- including their strict flags -- but everything else sees the
  -- name).
  local typename = 'Callable<' .. param_list_name
                   .. ' -> (' .. table.concat(return_names, ', ') .. ')>'
                   .. (strict and ' strict' or '')

  local signature_module = nil
  local subtype_module = nil

  return setmetatable({
    [matcher_kind_mark] = 'Callable',

    __name = typename,

    -- Expose the signature so other matchers can introspect.
    params = param_types,
    returns = return_types,
    strict = strict,

    __isinstance = function(self, value)
      -- Signature-wrapped functions declare their parameter and return
      -- types, so compare the declared signature against this
      -- matcher's with the standard variance rules (parameters are
      -- contravariant, returns are covariant), including variadic
      -- declarations (a trailing '...'); see
      -- llx.is_subtype.signature_compatible. Overload sets
      -- (llx.signature.Overload) are compared the same way:
      -- signature_compatible accepts the set when any of its
      -- declarations is compatible with this matcher. Variance applies
      -- in both lenient and strict mode: signature_compatible already
      -- enforces sound arity rules, and strict's extra constraints
      -- exist for raw functions, where no declared types are
      -- available. An AnyParams parameter list skips the parameter
      -- comparison entirely there, so only the declared returns are
      -- compared. The requires are deferred to avoid load-time cycles
      -- (llx.signature and llx.is_subtype depend, indirectly, on
      -- llx.types) and cached in upvalues.
      signature_module = signature_module or require 'llx.signature'
      if type(value) == 'table'
          and (isinstance(value, signature_module.Function)
               or isinstance(value, signature_module.Overload)) then
        subtype_module = subtype_module or require 'llx.is_subtype'
        return subtype_module.signature_compatible(value, self)
      end
      -- Raw functions carry no type information; arity (via
      -- debug.getinfo) is the strongest available check. By default the
      -- check is lenient: a vararg function can satisfy any parameter
      -- list, and a function declaring fewer parameters than the
      -- signature simply ignores the extra arguments (idiomatic Lua).
      -- A variadic parameter list (trailing '...') allows arbitrary
      -- extras, so in lenient mode it removes the upper bound on the
      -- declared arity and every function is accepted. With
      -- options.strict, the declared shape must match exactly: for a
      -- fixed list, exact arity and no varargs; for a variadic list,
      -- the function must itself be vararg with exactly the fixed
      -- prefix's parameter count. Note that debug.getinfo reports
      -- every C function as vararg with nparams == 0, so lenient mode
      -- accepts any C function and strict mode rejects them all --
      -- except against Callable({'...'}, ...), whose declared shape a
      -- C function matches exactly as far as the debug API can tell.
      -- With AnyParams no parameter shape is declared at all, so
      -- every function is accepted outright (strict is rejected at
      -- construction in that form).
      --
      -- A ParamSpec parameter list is treated the same way at the
      -- value level: this first iteration keeps ParamSpec a
      -- type-level-only construct (its capture/substitution lives
      -- entirely in signature_compatible), so a raw function -- which
      -- carries no declared parameter types to relate to a captured
      -- list -- places no checkable constraint and is accepted,
      -- gradually, exactly as under AnyParams. A *declared*
      -- (Signature/Overload) value above still goes through the sound
      -- type-level relation, where a top-level ParamSpec on the
      -- matcher (super) side stays universal and matches only an
      -- identical ParamSpec.
      if type(value) == 'function' then
        if params_any or params_spec then
          return true
        end
        local info = debug.getinfo(value, 'u')
        if strict then
          if params_variadic then
            return info.isvararg == true
               and info.nparams == params_fixed
          end
          return not info.isvararg and info.nparams == #param_types
        end
        if params_variadic then
          return true
        end
        return info.isvararg or info.nparams <= #param_types
      end
      -- Any other callable (a table or userdata with a __call
      -- metamethod) is accepted; no arity information is recoverable.
      -- is_callable can return nil; coerce to a proper boolean.
      return not not is_callable(value)
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

local function iterator_type_check(...)
  -- Iterator(T1, T2, ...): matches values usable as generic-for
  -- iterators yielding the given tuple per step -- the runtime analog
  -- of mypy's Iterator[T]. A trailing VARARG ('...') entry declares
  -- an unchecked variadic tail beyond the fixed, typed prefix,
  -- mirroring the Signature/Callable convention.
  --
  -- What the matcher can actually see (the same layering as
  -- Callable):
  --
  -- - Typed iterator wrappers (llx.typed_iterators.IteratorFunction)
  --   and typed generators (GeneratorInstance), which both declare
  --   their per-step yield types, are compared covariantly: the
  --   declared yields must be usable where this matcher's yields are
  --   expected, with the variadic arity rules of
  --   llx.is_subtype.signature_compatible's return lists. A typed
  --   generator additionally qualifies only when its declared
  --   returns list is empty: a generator whose body may return
  --   values on completion is not generic-for terminable (the loop
  --   would consume the return values as a step and resume a dead
  --   coroutine), so it is not usable as an iterator.
  -- - Raw functions carry no per-step type information, so by
  --   default they are accepted structurally (any function could be
  --   an iterator closure; generic-for's state/control arguments
  --   make arity heuristics meaningless here -- unlike Callable,
  --   there is no arity signal to check at all). This is the
  --   documented weak fallback; wrap the iterator
  --   (Yields{...} .. fn) to make the yield types checkable.
  -- - Other callables (tables or userdata with __call) are likewise
  --   accepted structurally by default.
  -- - A trailing {strict = true} options table -- Iterator's analog
  --   of Callable's strict option -- disables the structural
  --   fallback entirely: only values that *declare* their yields
  --   (the wrappers above) can match, so raw functions and unwrapped
  --   callables are rejected. Where Callable's strict tightens the
  --   raw-function check to the strongest available signal (exact
  --   arity), an iterator has no such signal, so the strongest
  --   tightening is to require a declaration.
  -- - Everything else -- including bare coroutine threads, which
  --   generic-for cannot drive -- is rejected.
  --
  -- The matcher never checks yielded values itself: per-step checking
  -- costs O(yield arity) on every loop iteration, so enforcement
  -- stays opt-in via the wrappers in llx.typed_iterators.
  local yield_count = select('#', ...)
  local yield_types = {...}
  -- A trailing options table is unambiguous in the vararg calling
  -- form: every real yield type entry is a matcher or class (a table
  -- carrying __isinstance), the VARARG string, or a stray marker
  -- (Rest/AnyParams, rejected below), so a table with no
  -- __isinstance and no marker can only be options.
  local strict = false
  local last = yield_types[yield_count]
  if yield_count > 0 and type(last) == 'table'
      and last.__isinstance == nil
      and not is_rest(last) and not is_any_params(last) then
    -- An empty table is neither a usable yield type (it could never
    -- match) nor a meaningful options table; silently discarding it
    -- would hide the mistake, so it fails loudly.
    if next(last) == nil then
      error('Iterator: expected a yield type or a non-empty '
        .. 'options table ({strict = ...}), got an empty table', 2)
    end
    for key in pairs(last) do
      if key ~= 'strict' then
        error("Iterator: unknown option '" .. tostring(key) .. "'", 2)
      end
    end
    if last.strict ~= nil and type(last.strict) ~= 'boolean' then
      error('Iterator: strict must be a boolean', 2)
    end
    strict = last.strict == true
    yield_types[yield_count] = nil
    yield_count = yield_count - 1
  end
  check_arguments_module =
      check_arguments_module or require 'llx.check_arguments'
  local vararg_marker = check_arguments_module.VARARG
  for i = 1, yield_count do
    if yield_types[i] == nil then
      error('Iterator: yield type ' .. i .. ' is nil', 2)
    end
    if i < yield_count and yield_types[i] == vararg_marker then
      exceptions_module = exceptions_module or require 'llx.exceptions'
      error(exceptions_module.ValueException(
        "Iterator: VARARG ('...') must be the last entry in "
        .. 'the yield type list', 2))
    end
  end
  -- Stray markers make a yield position silently unsatisfiable
  -- against declared yields while the lenient structural fallback
  -- would still accept every raw function; fail loudly at
  -- construction instead, the same policy Callable applies.
  reject_marker_entries(yield_types, 'Iterator')
  local yield_names = {}
  for i = 1, yield_count do
    yield_names[i] = type_name_of(yield_types[i])
  end
  -- Strictness is part of the matcher's identity, so it is encoded
  -- in the name (which is_subtype falls back to when comparing
  -- matchers), exactly as Callable does.
  local typename = 'Iterator<' .. table.concat(yield_names, ', ')
                   .. '>' .. (strict and ' strict' or '')

  -- Cached upvalues for deferred requires (the Callable pattern:
  -- llx.typed_iterators and llx.is_subtype depend on this module, so
  -- requiring them at load time would cycle).
  local typed_iterators_module = nil
  local subtype_module = nil

  return setmetatable({
    __name = typename,

    -- Expose the per-step yield types and strictness so callers can
    -- introspect.
    yields = yield_types,
    strict = strict,

    __isinstance = function(self, value)
      if type(value) == 'table' then
        typed_iterators_module = typed_iterators_module
            or require 'llx.typed_iterators'
        local is_generator = isinstance(
            value, typed_iterators_module.GeneratorInstance)
        if is_generator
            or isinstance(value,
                          typed_iterators_module.IteratorFunction)
        then
          -- A generator that may return values on completion cannot
          -- be driven to a clean stop by generic-for; see the note
          -- above.
          if is_generator and #value.returns > 0 then
            return false
          end
          -- Declared yields are covariant, with the same arity and
          -- variadic rules as a signature's return list; reuse
          -- signature_compatible on returns-only signatures. This
          -- path is the same in lenient and strict mode: strict
          -- exists to reject undeclared values, not to change the
          -- variance rules.
          subtype_module = subtype_module or require 'llx.is_subtype'
          return subtype_module.signature_compatible(
              {returns = value.yields}, {returns = yield_types})
        end
      end
      if strict then
        -- Strict mode: only declared yields count, and the wrapper
        -- paths above are the only declarations. Raw functions and
        -- unwrapped callables carry no per-step type information,
        -- so they are rejected rather than structurally accepted.
        return false
      end
      if type(value) == 'function' then
        return true
      end
      -- is_callable can return nil; coerce to a proper boolean.
      return not not is_callable(value)
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

local function generator_type_check(contract)
  -- Generator{yields=, accepts=, returns=, strict=}: matches typed
  -- coroutine generators by declared contract -- the runtime analog
  -- of mypy's Generator[YieldType, SendType, ReturnType]. Each list
  -- is optional (defaulting to empty); a trailing VARARG ('...')
  -- entry declares an unchecked variadic tail.
  --
  -- - Typed generators (llx.typed_iterators.GeneratorInstance)
  --   declare their contract, which is compared with the standard
  --   variance rules: yields and returns covariant, accepts (send
  --   types) contravariant; see
  --   llx.is_subtype.generator_compatible.
  -- - Plain coroutine threads match only structurally (the value is
  --   a thread): a raw thread carries no contract, so nothing about
  --   its yields, sends, or returns can be verified. This is the
  --   documented weak fallback; wrap the coroutine
  --   (Generates{...} .. body) to make the contract checkable.
  -- - strict = true -- Generator's analog of Iterator's strict
  --   option -- disables that structural fallback entirely: only
  --   values that *declare* their contract (GeneratorInstance
  --   wrappers) can match, so bare threads are rejected, with the
  --   variance rules for declared values unchanged. Like Iterator,
  --   a generator value offers no signal beyond its threadness, so
  --   the strongest tightening is to require a declaration. The
  --   flag lives inside the contract table rather than a trailing
  --   second argument: Generator's calling form is already a single
  --   named-key table (Iterator needed a *trailing* options table
  --   only because its yields are positional varargs), the contract
  --   keys are a fixed reserved set so 'strict' cannot collide with
  --   anything, and the single-table Generator{...} spelling is
  --   preserved.
  -- - Everything else is rejected -- including plain functions and
  --   coroutine.wrap results, which are indistinguishable from
  --   ordinary functions and are better matched by Iterator or
  --   Callable.
  --
  -- Like Iterator, the matcher never checks crossing values itself;
  -- enforcement stays opt-in via the wrapper.
  contract = contract or {}
  if type(contract) ~= 'table' then
    error('Generator: expected a contract table with optional '
      .. 'yields, accepts, and returns lists (and a strict flag)', 2)
  end
  for key in pairs(contract) do
    if key ~= 'yields' and key ~= 'accepts' and key ~= 'returns'
        and key ~= 'strict' then
      error("Generator: unknown contract key '" .. tostring(key)
        .. "'", 2)
    end
  end
  if contract.strict ~= nil and type(contract.strict) ~= 'boolean' then
    -- A truthy non-boolean would otherwise silently enable (or a
    -- falsy one disable) strictness; fail loudly instead, the same
    -- policy Iterator applies.
    error('Generator: strict must be a boolean', 2)
  end
  local strict = contract.strict == true
  local yields = contract.yields or {}
  local accepts = contract.accepts or {}
  local returns = contract.returns or {}
  -- Stray Rest/AnyParams markers make a contract position silently
  -- unsatisfiable against declared generators while the structural
  -- thread fallback still accepts every coroutine; fail loudly at
  -- construction instead, the same policy Callable and Iterator
  -- apply. A non-trailing VARARG ('...') is rejected for the same
  -- reason: generator_compatible treats only a *trailing* '...' as
  -- the variadic tail, so a mid-list occurrence is silently
  -- incompatible with every declared generator.
  check_arguments_module =
      check_arguments_module or require 'llx.check_arguments'
  local vararg_marker = check_arguments_module.VARARG
  local contract_lists =
      {{yields, 'yields'}, {accepts, 'accepts'}, {returns, 'returns'}}
  for _, list_entry in ipairs(contract_lists) do
    local list, list_name = list_entry[1], list_entry[2]
    reject_marker_entries(list, 'Generator')
    for i = 1, #list - 1 do
      if list[i] == vararg_marker then
        exceptions_module =
            exceptions_module or require 'llx.exceptions'
        error(exceptions_module.ValueException(
          "Generator: VARARG ('...') must be the last entry in "
          .. 'the ' .. list_name .. ' list', 2))
      end
    end
  end
  local function names_of(types)
    local names = {}
    for i, t in ipairs(types) do names[i] = type_name_of(t) end
    return table.concat(names, ', ')
  end
  -- The full contract is part of the matcher's identity -- the
  -- strict flag included, since it narrows which values match -- so
  -- it is encoded in the name (which is_subtype falls back to when
  -- comparing matchers: Generator has no structural subtype rule, so
  -- the name is what keeps the strict and lenient forms distinct
  -- there, exactly as for Iterator).
  local typename = 'Generator<yields=(' .. names_of(yields)
                   .. '), accepts=(' .. names_of(accepts)
                   .. '), returns=(' .. names_of(returns) .. ')>'
                   .. (strict and ' strict' or '')

  -- Cached upvalues for deferred requires; see Iterator above.
  local typed_iterators_module = nil
  local subtype_module = nil

  return setmetatable({
    __name = typename,

    -- Expose the contract (and strictness) so callers -- and
    -- generator_compatible -- can introspect.
    yields = yields,
    accepts = accepts,
    returns = returns,
    strict = strict,

    __isinstance = function(self, value)
      if type(value) == 'thread' then
        -- Weak structural fallback: it is a coroutine, but its
        -- contract is unknowable at runtime. Strict mode exists to
        -- disable exactly this branch -- only declared contracts
        -- (the wrapper path below) count.
        return not strict
      end
      if type(value) == 'table' then
        typed_iterators_module = typed_iterators_module
            or require 'llx.typed_iterators'
        if isinstance(value,
                      typed_iterators_module.GeneratorInstance) then
          subtype_module = subtype_module or require 'llx.is_subtype'
          return subtype_module.generator_compatible(value, self)
        end
      end
      return false
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

local function tuple_type_check(element_types)
  if type(element_types) ~= 'table' then
    error('Tuple: expected a list of element types', 2)
  end
  -- A trailing marker declares a variadic tail beyond the fixed,
  -- typed prefix:
  --
  -- - bare VARARG ('...'): the tail is unchecked, mirroring the
  --   Signature/Callable convention from llx.check_arguments.
  -- - Rest(T): every tail value must satisfy T -- the analog of
  --   mypy's `tuple[T, ...]` (which is spelled Tuple{Rest(T)}).
  --
  -- In both forms the tail may be empty. A non-final marker can
  -- never be satisfied, so it fails loudly at construction, the same
  -- policy Callable applies to its parameter and return lists.
  check_arguments_module =
      check_arguments_module or require 'llx.check_arguments'
  local vararg_marker = check_arguments_module.VARARG
  local declared_count = #element_types
  local last_entry = element_types[declared_count]
  local unchecked_tail = last_entry == vararg_marker
  local rest_type = nil
  if is_rest(last_entry) then
    rest_type = last_entry.element_type
  end
  local variadic = unchecked_tail or rest_type ~= nil
  local fixed_count = variadic and declared_count - 1
                      or declared_count
  for i = 1, fixed_count do
    local entry = element_types[i]
    if entry == vararg_marker or is_rest(entry) then
      exceptions_module = exceptions_module or require 'llx.exceptions'
      error(exceptions_module.ValueException(
        "Tuple: '...' and Rest(T) must be the last entry in "
        .. 'the element type list', 2))
    end
  end
  local element_names = {}
  for i = 1, fixed_count do
    element_names[i] = type_name_of(element_types[i])
  end
  -- The variadic tail is part of the matcher's identity, so it is
  -- encoded in the name (is_subtype compares Tuples structurally,
  -- but everything else -- error messages, Union names, matcher
  -- name equality -- sees the name), with distinct spellings for
  -- the unchecked ('...') and typed ('...T') forms.
  if unchecked_tail then
    element_names[fixed_count + 1] = '...'
  elseif rest_type ~= nil then
    element_names[fixed_count + 1] = '...' .. type_name_of(rest_type)
  end
  local typename = 'Tuple<' .. table.concat(element_names, ', ') .. '>'
  return setmetatable({
    __name = typename,

    -- Expose the positional type list (as declared, including any
    -- trailing marker) plus the derived shape so callers can
    -- introspect: fixed_count positions are typed individually,
    -- variadic says whether extra values are allowed, and rest_type
    -- (nil for the unchecked '...' form) types the tail.
    element_types = element_types,
    fixed_count = fixed_count,
    variadic = variadic,
    rest_type = rest_type,

    __isinstance = function(self, value)
      -- Accept any table-backed sequence: plain array tables and
      -- llx.Tuple instances alike (Tuple values are tables whose
      -- __len/__index metamethods make # and value[i] behave).
      -- Arity is checked with #, so values must be proper
      -- sequences; a table with trailing nils has an unspecified
      -- length in Lua, and a nil element can never satisfy a
      -- positional slot (use Union/Optional element types only
      -- with explicit non-nil sentinels).
      if type(value) ~= 'table' then return false end
      local length = #value
      if variadic then
        if length < fixed_count then return false end
      elseif length ~= fixed_count then
        return false
      end
      for i = 1, fixed_count do
        if not isinstance(value[i], element_types[i]) then
          return false
        end
      end
      if rest_type ~= nil then
        for i = fixed_count + 1, length do
          if not isinstance(value[i], rest_type) then
            return false
          end
        end
      end
      return true
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

local function literal_type_check(value_list)
  if type(value_list) ~= 'table' then
    error('Literal: expected a list of allowed values', 2)
  end
  local value_names = {}
  for i, allowed in ipairs(value_list) do
    -- Only equality-comparable scalar values make sense as literals
    -- (the same restriction Python's typing.Literal applies). Tables
    -- are rejected because == on tables is identity (or a custom
    -- __eq), which is rarely what a literal means.
    local allowed_type = type(allowed)
    if allowed_type ~= 'string' and allowed_type ~= 'number'
        and allowed_type ~= 'boolean' then
      error('Literal: values must be strings, numbers, or booleans; '
        .. 'got ' .. allowed_type, 2)
    end
    if allowed_type == 'string' then
      value_names[i] = "'" .. allowed .. "'"
    else
      value_names[i] = tostring(allowed)
    end
  end
  if #value_names == 0 then
    error('Literal: expected at least one value', 2)
  end
  local typename = 'Literal{' .. table.concat(value_names, ', ') .. '}'
  return setmetatable({
    __name = typename,

    -- Expose the allowed values so callers can introspect.
    values = value_list,

    __isinstance = function(self, value)
      for _, allowed in ipairs(value_list) do
        if value == allowed then
          return true
        end
      end
      return false
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

-- Private key under which a branded wrapper stores its underlying
-- value. The key is a module-local table, so it cannot be forged (or
-- even observed) outside this module.
local newtype_raw_key = {}

-- Marker key identifying NewType matcher tables, used to walk chains
-- of brands (NewType over NewType). A non-string key keeps it out of
-- the matcher's public field namespace.
local newtype_mark = {}

-- Cached upvalue for the deferred require of llx.hash (deferred to
-- avoid load-time cycles; llx.hash pulls in the exception hierarchy).
local hash_module = nil

-- Fully unwraps a branded value: follows the chain of wrappers down
-- to the first non-branded value. Non-branded values pass through
-- unchanged, so this is safe to apply to both operands of a binary
-- operator.
local function newtype_unwrap(value)
  while type(value) == 'table' do
    local raw = rawget(value, newtype_raw_key)
    if raw == nil then break end
    value = raw
  end
  return value
end

-- Cached upvalue for the deferred require of llx.getclass, which owns
-- the shared value-description helper (deferred to avoid a load-time
-- cycle: llx.getclass requires llx.types and therefore this module).
-- The helper is class-aware, so construction errors describe class
-- instances as "an instance of Animal" rather than a bare "table".
local describe_getclass_module = nil

local function describe_value(value)
  describe_getclass_module =
      describe_getclass_module or require 'llx.getclass'
  return describe_getclass_module.describe_value(value)
end

local function new_type_check(name, base_type)
  -- Branded runtime types, the runtime analog of Python's
  -- NewType('UserId', int): semantically distinct types over the same
  -- representation, so a UserId cannot be passed where an OrderId is
  -- expected. Python's NewType is erased at runtime; llx is a runtime
  -- checker, so the constructor brands the value instead by wrapping
  -- it in a small table marked with the brand.
  --
  -- The returned object serves both roles:
  --
  -- - Constructor: UserId(v) validates v against base_type and
  --   returns a branded wrapper. Passing a value that already carries
  --   this brand (or a brand built on top of it) returns it
  --   unchanged.
  -- - Matcher: isinstance(v, UserId) accepts only branded values.
  --   is_subtype(UserId, base_type) holds (the matcher exposes the
  --   base through __superclasses), so brands widen to their base at
  --   the type level.
  --
  -- Wrappers forward the value-level operators (arithmetic, bitwise,
  -- comparison, concat, len, call, tostring) to the underlying value,
  -- unwrapping branded operands on either side. Unwrapping is
  -- explicit otherwise: wrapper:get() returns the underlying value
  -- (one brand level; 'get' is therefore a reserved field name on
  -- wrappers). Known limitations of the wrapper strategy:
  --
  -- - A branded primitive is a table at the value level, so
  --   isinstance(UserId(1), Integer) is false, and a branded value
  --   never compares equal (==) to an unbranded one, whatever the
  --   payload type. Unwrap first.
  -- - Method-call syntax is not forwarded for string bases:
  --   branded:upper() would pass the wrapper as self. Use
  --   branded:get():upper().
  -- - Wrappers are read-only; mutate table-based values through
  --   :get(). Reads of table fields are forwarded.
  -- - Brand names should be unique: is_subtype compares matchers by
  --   __name (a pre-existing caveat), so two NewTypes sharing a name
  --   are mutual subtypes at the type level even though isinstance
  --   still tells their values apart.
  if type(name) ~= 'string' then
    error('NewType: expected a string name, got ' .. type(name), 2)
  end
  if type(base_type) ~= 'table' or base_type.__isinstance == nil then
    error('NewType: base type must be a type matcher or class with '
      .. '__isinstance', 2)
  end

  local matcher

  local function get(self)
    return rawget(self, newtype_raw_key)
  end

  -- Note: the wrapper metatable deliberately carries no __name.
  -- llx.hash.hash_value mixes the metatable __name into the hash
  -- before consulting __hash, and __eq below is erased across brands
  -- (UserId(1) == OrderId(1)), so a per-brand __name would break the
  -- equal-values-hash-equally invariant.
  local wrapper_metatable
  wrapper_metatable = {
    __add = function(a, b)
      return newtype_unwrap(a) + newtype_unwrap(b)
    end,
    __sub = function(a, b)
      return newtype_unwrap(a) - newtype_unwrap(b)
    end,
    __mul = function(a, b)
      return newtype_unwrap(a) * newtype_unwrap(b)
    end,
    __div = function(a, b)
      return newtype_unwrap(a) / newtype_unwrap(b)
    end,
    __mod = function(a, b)
      return newtype_unwrap(a) % newtype_unwrap(b)
    end,
    __pow = function(a, b)
      return newtype_unwrap(a) ^ newtype_unwrap(b)
    end,
    __idiv = function(a, b)
      return newtype_unwrap(a) // newtype_unwrap(b)
    end,
    __band = function(a, b)
      return newtype_unwrap(a) & newtype_unwrap(b)
    end,
    __bor = function(a, b)
      return newtype_unwrap(a) | newtype_unwrap(b)
    end,
    __bxor = function(a, b)
      return newtype_unwrap(a) ~ newtype_unwrap(b)
    end,
    __shl = function(a, b)
      return newtype_unwrap(a) << newtype_unwrap(b)
    end,
    __shr = function(a, b)
      return newtype_unwrap(a) >> newtype_unwrap(b)
    end,
    __unm = function(a)
      return -newtype_unwrap(a)
    end,
    __bnot = function(a)
      return ~newtype_unwrap(a)
    end,
    __concat = function(a, b)
      return newtype_unwrap(a) .. newtype_unwrap(b)
    end,
    __len = function(a)
      return #newtype_unwrap(a)
    end,
    __eq = function(a, b)
      -- Equality is on the underlying values, so two brands over the
      -- same representation compare equal when their payloads do
      -- (matching Python, where NewType is erased and equality falls
      -- through to the base value). A branded value never equals an
      -- unbranded one, though: for primitive payloads Lua already
      -- never consults __eq across types, and for table payloads the
      -- wrapper refuses explicitly, keeping == uniform across payload
      -- types and consistent with __hash (llx.hash mixes the outer
      -- type name into a table's hash, so a wrapper and its raw table
      -- payload can never hash equally).
      local a_branded =
          type(a) == 'table' and rawget(a, newtype_raw_key) ~= nil
      local b_branded =
          type(b) == 'table' and rawget(b, newtype_raw_key) ~= nil
      if not (a_branded and b_branded) then
        return false
      end
      return newtype_unwrap(a) == newtype_unwrap(b)
    end,
    __lt = function(a, b)
      return newtype_unwrap(a) < newtype_unwrap(b)
    end,
    __le = function(a, b)
      return newtype_unwrap(a) <= newtype_unwrap(b)
    end,
    __call = function(self, ...)
      return newtype_unwrap(self)(...)
    end,
    __tostring = function(self)
      return tostring(newtype_unwrap(self))
    end,
    -- __eq implies __hash (type regularity); hash the underlying
    -- value so values that compare equal hash equal, including
    -- across sibling brands.
    __hash = function(self, running_hash)
      hash_module = hash_module or require 'llx.hash'
      return hash_module.hash_value(
        newtype_unwrap(self), running_hash)
    end,

    __index = function(self, key)
      if key == 'get' then return get end
      -- Forward field reads so branded records stay usable without
      -- unwrapping. Non-table payloads have no fields to forward.
      local raw = rawget(self, newtype_raw_key)
      if type(raw) == 'table' then
        return raw[key]
      end
      return nil
    end,

    __newindex = function(self, key, value)
      error(name .. ' values are read-only; unwrap with :get() to '
        .. 'mutate the underlying value', 2)
    end,
  }

  matcher = setmetatable({
    [newtype_mark] = true,

    __name = name,

    -- Expose the base so callers can introspect.
    base_type = base_type,

    -- Participate in is_subtype's superclass-chain walk, so
    -- is_subtype(UserId, Integer) holds (and transitively
    -- is_subtype(UserId, Number) via numeric widening).
    __superclasses = {base_type},

    __isinstance = function(self, value)
      if type(value) ~= 'table' then return false end
      local value_metatable = getmetatable(value)
      if type(value_metatable) ~= 'table' then return false end
      -- Walk the brand chain so a value branded with a NewType built
      -- on top of this one also matches (an AdminId is a UserId).
      local brand = value_metatable.__newtype
      while brand ~= nil do
        if rawequal(brand, self) then return true end
        local brand_base = rawget(brand, 'base_type')
        if type(brand_base) ~= 'table'
            or rawget(brand_base, newtype_mark) == nil then
          return false
        end
        brand = brand_base
      end
      return false
    end,
  }, {
    __call = function(self, value)
      -- Already carrying this brand (or one derived from it): return
      -- unchanged rather than double-wrapping.
      if self:__isinstance(value) then
        return value
      end
      if value == nil then
        -- A branded nil would be indistinguishable from an unbranded
        -- payload when unwrapping; reject it outright.
        error(name .. ': cannot brand nil', 2)
      end
      if not isinstance(value, base_type) then
        error(name .. ': expected ' .. type_name_of(base_type)
          .. ', got ' .. describe_value(value), 2)
      end
      return setmetatable(
        {[newtype_raw_key] = value}, wrapper_metatable)
    end,

    __tostring = function(self)
      return self.__name
    end,
  })

  -- The wrapper metatable carries its brand so the matcher above can
  -- identify branded values. Assigned after construction because the
  -- metatable and the matcher reference each other.
  wrapper_metatable.__newtype = matcher

  return matcher
end

-- Returns true when value is a class object produced by llx.class (a
-- class table proxy), as opposed to an instance, a plain table, or a
-- non-table. Two facts uniquely identify a class proxy (see the
-- implementation notes in src/class.lua):
--
-- - getmetatable(proxy) returns the proxy itself (the proxy metatable
--   sets __metatable to the proxy), whereas getmetatable(instance)
--   returns the instance's class proxy, never the instance, and a
--   plain table's metatable (if any) is some other table.
-- - The proxy's __index resolves against the internal class table,
--   where __is_llx_class is rawset to true on every class; instances
--   would also inherit the flag, but the metatable check above has
--   already excluded them.
local function is_class_object(value)
  return type(value) == 'table'
     and rawequal(getmetatable(value), value)
     and value.__is_llx_class == true
end

local function class_of_type_check(base_class)
  -- ClassOf(C): matches class objects (values created by llx.class),
  -- never instances -- the runtime analog of mypy's type[C]. A value
  -- matches when it is a class and is C itself or a (transitive)
  -- subclass of C, per llx.is_subtype. ClassOf() with no argument
  -- matches any class, mirroring Python's bare `type`.
  --
  -- Only class objects are accepted as the base: string class names
  -- are rejected because is_subtype supports strings for name
  -- equality only, so ClassOf('Animal') could never walk the
  -- hierarchy and would silently match nothing but the exact name.
  -- Type matchers (Integer, Union, NewType, ...) are rejected too:
  -- they are not classes, so no value could ever match.
  --
  -- Caveat (inherited from is_subtype's equality rule): two distinct
  -- classes sharing a non-anonymous __name compare as equal, so
  -- ClassOf(Animal) also matches an unrelated class named 'Animal'.
  -- Keep class names unique.
  if base_class ~= nil and not is_class_object(base_class) then
    local description = describe_value(base_class)
    if type(base_class) == 'table'
        and is_class_object(getmetatable(base_class)) then
      -- A likely mistake: an *instance* where its class was meant.
      -- describe_value already renders it as "an instance of X";
      -- point at the fix.
      description = description .. ' (pass the class itself)'
    end
    error('ClassOf: expected a class object (or no argument), got '
      .. description, 2)
  end
  local typename = base_class == nil and 'ClassOf'
      or 'ClassOf<' .. type_name_of(base_class) .. '>'

  -- Cached upvalue for the deferred require of llx.is_subtype
  -- (deferred to avoid a load-time cycle: llx.is_subtype requires
  -- this module; the Callable pattern above).
  local subtype_module = nil

  return setmetatable({
    __name = typename,

    -- Expose the base so callers can introspect. nil for the bare
    -- match-any-class form.
    base_class = base_class,

    __isinstance = function(self, value)
      if not is_class_object(value) then return false end
      if base_class == nil then return true end
      subtype_module = subtype_module or require 'llx.is_subtype'
      return subtype_module.is_subtype(value, base_class)
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

-- Marker key identifying Lazy matchers. A module-local table key
-- cannot be forged (or observed) outside this module, so nothing else
-- can accidentally look like a Lazy. The key doubles as the force
-- handle: it maps to the matcher's resolve function, which is how
-- chain flattening below and resolve_lazy reach into a Lazy.
local lazy_mark = {}

-- Monotonic id so every unresolved Lazy gets a distinct placeholder
-- name. A shared placeholder would make every container that embeds
-- an unresolved Lazy of the same shape (e.g. two different recursive
-- ListOf types) freeze identical names, and is_subtype's
-- name-equality fallback would then treat structurally different
-- recursive types as mutual subtypes.
local lazy_counter = 0

local function lazy_type_check(thunk)
  -- Lazy(thunk): a deferred type reference, the analog of mypy's
  -- recursive type aliases and forward references. The thunk is not
  -- called at construction; it runs on the first __isinstance check
  -- (or the first is_subtype comparison, which forces both operands),
  -- and the matcher it returns is cached, so the thunk is called at
  -- most once on success. This makes self-referential types
  -- expressible with plain local variables:
  --
  --   local Json
  --   Json = Union{String, Number, Boolean, Nil,
  --                ListOf(Lazy(function() return Json end)),
  --                Dict(String, Lazy(function() return Json end))}
  --
  -- Note the two-statement form: `local Json = Union{...}` would
  -- capture an outer (usually nil) Json in the thunk, because the
  -- local is not in scope inside its own initializer.
  --
  -- Naming: reading __name (or tostring) never forces resolution --
  -- it reports a unique placeholder ('Lazy<?#1>', 'Lazy<?#2>', ...)
  -- until the matcher has been resolved, after which it adopts the
  -- resolved matcher's name. Consequently a matcher that embeds an
  -- unresolved Lazy computes its own (construction-time) name with
  -- the placeholder; that name is frozen, which is inherent to
  -- laziness. The placeholder is unique per Lazy so two structurally
  -- different recursive containers never freeze the same name (which
  -- is_subtype's name-equality fallback would conflate); the flip
  -- side is that separately constructed but identical recursive
  -- containers do not compare equal by name -- compare by identity,
  -- or let is_subtype force the Lazy itself.
  --
  -- Cycles: a Lazy that resolves -- directly or through a chain of
  -- Lazy matchers -- back to itself has no underlying type, so
  -- resolution raises a clear error instead of overflowing the stack.
  -- Chains of Lazy flatten to the first non-Lazy matcher at
  -- resolution time, so a check never dispatches from one Lazy to
  -- another. A cycle routed through a structural matcher with no
  -- non-recursive member (e.g. `local A; A = Union{Lazy(-> A)}`) is
  -- an uninhabitable type with no base case; it cannot be detected
  -- at resolution time. is_subtype detects the resulting
  -- self-dependent comparison and raises a clear error, and the
  -- union member walk applies the same pair-based occurs check at
  -- the value level, so isinstance against such a type raises a
  -- clear "cyclic type check" error instead of diverging.
  --
  -- Errors raised by the thunk itself propagate and are not cached:
  -- a later check retries resolution.
  if not is_callable(thunk) then
    error('Lazy: expected a callable thunk, got ' .. type(thunk), 2)
  end

  lazy_counter = lazy_counter + 1
  local placeholder = 'Lazy<?#' .. lazy_counter .. '>'

  local resolved = nil
  local resolving = false

  local function resolve()
    if resolved ~= nil then
      return resolved
    end
    if resolving then
      error('Lazy: resolution cycle detected (the thunk resolves, '
        .. 'directly or through a chain of Lazy matchers, back to '
        .. 'this Lazy)', 2)
    end
    resolving = true
    local ok, result = pcall(function()
      local r = thunk()
      -- Flatten chains of Lazy so the cached matcher is never itself
      -- a Lazy: a mutually-referential pair would otherwise bounce
      -- between the two __isinstance implementations without bound
      -- at check time. Forcing the inner Lazy re-enters its own
      -- resolve, so a chain that loops back trips the resolving
      -- guard above.
      while type(r) == 'table' and rawget(r, lazy_mark) ~= nil do
        r = rawget(r, lazy_mark)()
      end
      return r
    end)
    resolving = false
    if not ok then
      error(result, 0)
    end
    if type(result) ~= 'table' or result.__isinstance == nil then
      local hint = ''
      if result == nil then
        -- The classic forward-reference pitfall: `local T = ...`
        -- captures an outer T inside the thunk. Point at the fix.
        hint = " (declare the local before assigning it: 'local T' "
          .. "on its own line, then 'T = ...')"
      end
      error('Lazy: thunk returned ' .. describe_value(result)
        .. '; expected a type matcher or class with __isinstance'
        .. hint, 2)
    end
    resolved = result
    return resolved
  end

  return setmetatable({
    [lazy_mark] = resolve,

    __isinstance = function(self, value)
      return isinstance(value, resolve())
    end,
  }, {
    __index = function(self, key)
      if key == '__name' then
        -- Non-forcing: introspection must stay side-effect free.
        if resolved ~= nil then
          return type_name_of(resolved)
        end
        return placeholder
      end
      if key == '__validate' then
        -- Forwarded so Schema's per-type constraint hooks (minimum,
        -- pattern, properties, ...) apply through a Lazy type field.
        -- This read only happens while validating a value, where
        -- resolution is needed anyway, so forcing here is sound.
        return resolve().__validate
      end
      return nil
    end,
    __tostring = function(self)
      return self.__name
    end,
  })
end

-- Sees through Lazy matchers: forces a Lazy (caching its resolution)
-- and returns the resolved matcher; any other value passes through
-- unchanged. llx.is_subtype applies this to both operands so the
-- subtype relation always compares resolved matchers; it is exported
-- for the same use elsewhere.
local function resolve_lazy_matcher(t)
  if type(t) == 'table' then
    local force = rawget(t, lazy_mark)
    if force ~= nil then
      return force()
    end
  end
  return t
end

-- Marker key identifying TypeVar matchers. A module-local table key
-- cannot be forged (or observed) outside this module, so nothing else
-- can accidentally look like a TypeVar. is_type_var (exported below)
-- is the public way to recognize one.
local type_var_mark = {}

-- Returns true when value is a TypeVar produced by the TypeVar
-- factory below. Used by llx.is_subtype to exclude type variables
-- from the variance relation (only a TypeVar's identity relates it to
-- another type; see that module).
local function is_type_var(value)
  return type(value) == 'table'
     and rawget(value, type_var_mark) == true
end

-- Cached upvalue for the deferred require of llx.getclass (deferred
-- to avoid a load-time cycle: llx.getclass requires llx.types and
-- therefore this module).
local getclass_module = nil

-- Infers the type a TypeVar binds from its first witness value: the
-- narrowest built-in singleton for numbers (Integer or Float, per
-- math.type), otherwise the value's class per llx.getclass (the
-- exact class of an instance, or the built-in singleton for other
-- primitives). Binding narrowly is what makes params={T, T} reject
-- f(1, 1.5): the witness 1 binds T to Integer, which 1.5 fails.
local function infer_type_var_binding(value)
  local number_type = math.type(value)
  if number_type == 'integer' then
    return Integer
  end
  if number_type == 'float' then
    return Float
  end
  getclass_module = getclass_module or require 'llx.getclass'
  return getclass_module.getclass(value)
end

-- Checks a later occurrence of a bound TypeVar: the value must be
-- consistent with the recorded binding. Bindings produced by
-- llx.getclass are usually matchers or classes with __isinstance, in
-- which case the value-level check applies (so a subclass instance is
-- accepted after a superclass binding). Everything else falls back to
-- exact-class identity: a witness whose class is a plain metatable
-- with no __isinstance, a non-table binding (getmetatable on a
-- __metatable-protected value yields the protection value, whatever
-- its type), or a metatable whose own strict __index would raise on
-- the field probe (hence the pcall; the lookup cannot be a rawget
-- because class proxies resolve __isinstance through their __index).
local function type_var_consistent(value, binding)
  if type(binding) == 'table' then
    local ok, field = pcall(function()
      return binding.__isinstance
    end)
    if ok and field ~= nil then
      return isinstance(value, binding)
    end
  end
  return rawequal(infer_type_var_binding(value), binding)
end

-- Collects `binding` and its transitive declared ancestors (the
-- __superclasses chain, nearest first, declaration order) into
-- `list`. Bindings are inferred witness types -- class proxies,
-- built-in singletons, or plain metatables -- so the field probe is
-- pcall-guarded against strict __index metatables, the same caution
-- type_var_consistent applies to its __isinstance probe. Class
-- graphs are acyclic by construction, so no cycle guard is needed.
local function collect_declared_ancestors(binding, list)
  list[#list + 1] = binding
  local ok, superclasses = pcall(function()
    return binding.__superclasses
  end)
  if ok and type(superclasses) == 'table' then
    for _, superclass in ipairs(superclasses) do
      collect_declared_ancestors(superclass, list)
    end
  end
end

local function is_numeric_binding(binding)
  return rawequal(binding, Integer)
      or rawequal(binding, Float)
      or rawequal(binding, Number)
end

-- Best-effort name of a binding for the deterministic tie-break in
-- join_type_var_bindings. pcall-guarded like the probes above.
local function binding_name(binding)
  local ok, name = pcall(function()
    return binding.__name
  end)
  if ok and type(name) == 'string' then
    return name
  end
  return ''
end

-- The join (least common supertype) of a set of witness types, or
-- nil when none exists. `list` holds the distinct witnesses a
-- TypeVar has accumulated inside commutative regions of the current
-- scope; `extra` is the new witness, not already in the list by
-- identity. The join is computed over the whole set at once -- the
-- intersection of every witness's declared ancestor set -- which is
-- symmetric in the witnesses, so the result cannot depend on the
-- order pairs yields a container's elements. (A pairwise fold would
-- not be associative under multiple inheritance: an ambiguous
-- intermediate tie-break can drift the fold to a different, coarser
-- result depending on encounter order.)
--
-- Rules, mirroring how a static checker joins types:
--
-- - A set of numeric witnesses (Integer, Float, or an accumulated
--   Number) joins at Number, the same widening is_subtype applies at
--   the type level.
-- - Class hierarchies join at the most derived ancestor common to
--   every witness (walking __superclasses transitively, self
--   included, so a subclass joins with its superclass at the
--   superclass).
-- - Witnesses whose values are certainly tables -- class objects and
--   the Table singleton -- but share no declared ancestor join at
--   Table, the top of the table kinds (the getclass analog of
--   joining unrelated classes at `object`). This also keeps the join
--   symmetric with type_var_consistent, where a Table binding admits
--   any table-typed value including class instances.
-- - Everything else (mixed primitives, plain metatables with no
--   shared ancestry -- whose values might be tables or userdata, so
--   widening to Table would be unsound) has no join: the element
--   check fails, deterministically, in every iteration order.
--
-- Multiple inheritance can leave several incomparable most-derived
-- common ancestors; the tie is broken by name over the (symmetric)
-- candidate set, so the choice is deterministic for uniquely named
-- classes even where a unique least supertype does not exist.
local function join_witness_set(list, extra)
  local count = #list
  if count == 0 then
    return extra
  end
  local all_numeric = is_numeric_binding(extra)
  for i = 1, count do
    if not all_numeric then
      break
    end
    all_numeric = is_numeric_binding(list[i])
  end
  if all_numeric then
    return Number
  end
  if type(extra) ~= 'table' then
    return nil
  end
  -- Identity comparisons suffice throughout: witness types and
  -- __superclasses entries are both the public class proxy objects
  -- (or singletons), of which there is exactly one per class.
  -- Candidates start as the new witness's ancestors and are
  -- intersected with every accumulated witness's ancestor set.
  local candidates = {}
  collect_declared_ancestors(extra, candidates)
  for i = 1, count do
    local witness = list[i]
    if type(witness) ~= 'table' then
      return nil
    end
    local ancestors = {}
    collect_declared_ancestors(witness, ancestors)
    local present = {}
    for j = 1, #ancestors do
      present[ancestors[j]] = true
    end
    local kept, seen = {}, {}
    for j = 1, #candidates do
      local candidate = candidates[j]
      if present[candidate] and not seen[candidate] then
        seen[candidate] = true
        kept[#kept + 1] = candidate
      end
    end
    candidates = kept
    if #candidates == 0 then
      break
    end
  end
  if #candidates == 0 then
    if not (is_class_object(extra) or rawequal(extra, Table)) then
      return nil
    end
    for i = 1, count do
      local witness = list[i]
      if not (is_class_object(witness) or rawequal(witness, Table))
      then
        return nil
      end
    end
    return Table
  end
  if #candidates == 1 then
    return candidates[1]
  end
  -- Keep the most derived common ancestors: drop any candidate that
  -- is a strict ancestor of another candidate, then break ties by
  -- name.
  local strictly_above = {}
  for i = 1, #candidates do
    local ancestors = {}
    collect_declared_ancestors(candidates[i], ancestors)
    for j = 2, #ancestors do
      strictly_above[ancestors[j]] = true
    end
  end
  local best = nil
  for i = 1, #candidates do
    local candidate = candidates[i]
    if not strictly_above[candidate] then
      if best == nil or binding_name(candidate) < binding_name(best)
      then
        best = candidate
      end
    end
  end
  return best
end

local function type_var_type_check(name, opts)
  -- TypeVar(name, opts): a generic type variable with per-call
  -- binding, the runtime analog of mypy's TypeVar('T'). Within a
  -- single signature-checked call (llx.signature.Function, or an
  -- Overload candidate), the variable binds to the type of the first
  -- value checked against it -- inferred narrowly, see
  -- infer_type_var_binding above -- and every later position naming
  -- the same variable (in params or returns, bare or nested inside a
  -- parameterized matcher such as ListOf(T) or Dict(K, V)) must be
  -- consistent with that binding:
  --
  --   local T = TypeVar('T')
  --   local first = Signature{params={ListOf(T)}, returns={T}}
  --       .. function(xs) return xs[1] end
  --
  -- opts.bound constrains admissible values: every value checked
  -- against the variable must satisfy isinstance(value, bound),
  -- whether it is the binding witness or a later occurrence (checking
  -- every occurrence keeps structural bounds such as Protocol sound
  -- even when the inferred binding is coarse, e.g. Table).
  --
  -- Semantics and caveats (first iteration; deliberate, documented
  -- choices):
  --
  -- - In positional contexts (params, returns, and ipairs-ordered
  --   containers such as ListOf and Tuple, outside any
  --   pairs-iterated container), binding is
  --   first-witness, one-pass: there is no constraint solving, so
  --   with params={T, T} the call f(cat, animal) is rejected while
  --   f(animal, cat) is accepted (the second value is checked
  --   against the first one's binding with isinstance, which admits
  --   subclass instances). Likewise f(1, 1.5) is rejected: 1 binds T
  --   to Integer, not Number. Positional order is part of the
  --   value, so this is deterministic.
  -- - Inside pairs-iterated containers (Dict, SetOf), whose element
  --   order is semantically meaningless, binding is instead
  --   order-independent: the variable binds the *join* (least common
  --   supertype) of every witness the container yields --
  --   Integer/Float widen to Number, a class joins its subclasses,
  --   unrelated classes join at their nearest common declared
  --   ancestor (or at Table when there is none), and elements with
  --   no join at all (e.g. a Number next to a String, or two
  --   unrelated plain-metatable values) fail the check in every
  --   iteration order. The join extends to witnesses reached
  --   *through* the container's elements, including those inside
  --   nested ipairs-ordered containers: the outer pairs order
  --   decides which nested list is checked first, so
  --   Dict(String, ListOf(T)) must join across (and therefore
  --   within) its lists to stay order-independent -- a list that a
  --   bare ListOf(T) would reject for mixing Integer and Float is
  --   accepted inside a Dict, binding T to Number. See
  --   join_witness_set and the commutative witness region machinery
  --   above.
  -- - Speculative matcher branches roll back: a Union member that
  --   binds a variable and then rejects the value restores the
  --   bindings that were in place before the branch, so union member
  --   order is not observable through stale bindings (see
  --   save_type_var_bindings). A member that *matches* keeps its
  --   bindings, and members are still tried in declaration order, so
  --   with Union{Any, ListOf(T)} the Any member wins first and T is
  --   never bound -- order the specific member first, as with
  --   Overload.
  -- - Bindings are per call and identity-keyed: two TypeVars sharing
  --   a name are independent variables, and a fresh scope is opened
  --   for every checked call, so bindings never leak between calls,
  --   recursive activations, or coroutines (see
  --   type_var_scope_stack).
  -- - Outside any signature-checked call, plain isinstance treats the
  --   variable as unconstrained-but-bounded: isinstance(v, T) is true
  --   whenever v satisfies opts.bound (or always, without a bound).
  --   The wrapped function's own body runs outside the scope, so
  --   plain isinstance there behaves the same way.
  -- - Type-level relations: plain llx.is_subtype relates a TypeVar
  --   only to itself (and to Any, as every type is). Inside
  --   llx.is_subtype.signature_compatible -- and therefore the
  --   Callable matcher -- the *candidate* signature's variables
  --   unify against their concrete counterparts (the first
  --   occurrence instantiates the variable, later occurrences must
  --   satisfy the instantiation with their position's variance, and
  --   bounds are respected), so a generic signature such as the
  --   `first` example above is compatible with
  --   Callable({ListOf(Integer)}, {Integer}). That relation reads
  --   the variable as universally quantified over the declared
  --   signature; it deliberately does not model the narrower
  --   first-witness runtime binding described here (see the generic
  --   signatures section of signature_compatible for the exact
  --   divergences). ParamSpec/TypeVarTuple analogs are follow-ups.
  -- - Like NewType, the matcher's __name is the given name. Matchers
  --   with structural is_subtype rules (Tuple, Union, ListOf, SetOf,
  --   Dict, Callable) compare their element types recursively, so
  --   the TypeVar identity rule reaches through them: two ListOf(T)s
  --   built from distinct TypeVars both named 'T' are unrelated at
  --   the type level. Matchers that still compare by name (Iterator,
  --   Generator, Protocol, ...) embed only the name, so distinct
  --   TypeVars are conflated one level up inside them. Keep TypeVar
  --   names unique where that matters.
  if type(name) ~= 'string' then
    error('TypeVar: expected a string name, got ' .. type(name), 2)
  end
  opts = opts or {}
  if type(opts) ~= 'table' then
    error('TypeVar: expected an options table, got ' .. type(opts), 2)
  end
  for key in pairs(opts) do
    if key ~= 'bound' then
      error("TypeVar: unknown option '" .. tostring(key) .. "'", 2)
    end
  end
  local bound = opts.bound
  if bound ~= nil
      and (type(bound) ~= 'table' or bound.__isinstance == nil) then
    error('TypeVar: bound must be a type matcher or class with '
      .. '__isinstance', 2)
  end

  local var
  var = setmetatable({
    [type_var_mark] = true,

    __name = name,

    -- Expose the bound so callers can introspect. nil when
    -- unconstrained.
    bound = bound,

    __isinstance = function(self, value)
      -- The bound applies to every occurrence, bound or not.
      if bound ~= nil and not isinstance(value, bound) then
        return false
      end
      local scope = type_var_scope_stack[#type_var_scope_stack]
      if scope == nil then
        -- No active binding scope (plain isinstance, outside any
        -- signature-checked call): the variable is unconstrained
        -- beyond its bound.
        return true
      end
      local binding = scope[var]
      if binding == nil then
        -- First occurrence in this call: this value is the witness;
        -- record its inferred type as the binding.
        scope[var] = infer_type_var_binding(value)
        return true
      end
      if (scope[commutative_mark] or 0) > 0 then
        -- Inside a commutative witness region (a pairs-iterated
        -- container): consistency must be symmetric in the values
        -- seen so far, so the witness set accumulated on the scope
        -- is extended and the binding widened to the join of the
        -- whole set, failing only when no join exists. The
        -- asymmetric type_var_consistent path below would make the
        -- verdict depend on iteration order.
        local all_witnesses = scope[witnesses_mark]
        if all_witnesses == nil then
          all_witnesses = {}
          scope[witnesses_mark] = all_witnesses
        end
        local list = all_witnesses[var]
        if list == nil then
          -- Seed with the pre-region binding (a positional witness,
          -- since joins only happen where a set already exists): it
          -- constrains the join like any other witness.
          list = {binding}
          all_witnesses[var] = list
        end
        local witness = infer_type_var_binding(value)
        for i = 1, #list do
          if rawequal(list[i], witness) then
            -- Already part of the join; nothing can change.
            return true
          end
        end
        local joined = join_witness_set(list, witness)
        if joined == nil then
          return false
        end
        list[#list + 1] = witness
        scope[var] = joined
        return true
      end
      return type_var_consistent(value, binding)
    end,
  }, {
    __tostring = function(self)
      return self.__name
    end,
  })
  return var
end

local function param_spec_type_check(name)
  -- ParamSpec(name): a parameter-list variable, the runtime analog of
  -- Python's typing.ParamSpec. Passed *in place of* a Callable's
  -- parameter type list -- Callable(P, {R}) -- it captures "the same
  -- parameter list as some other signature", so forwarding wrappers
  -- (decorators, tracing/memoization combinators) that preserve a
  -- wrapped function's parameters can be typed without erasing them
  -- to AnyParams or freezing them to one concrete shape. Its canonical
  -- use is the decorator shape
  --
  --   local P, T = ParamSpec('P'), TypeVar('T')
  --   Callable({Callable(P, {T})}, {Callable(P, {T})})
  --
  -- which llx.is_subtype.signature_compatible relates to a concrete
  --   Callable({Callable({Integer}, {String})},
  --            {Callable({Integer}, {String})})
  -- by instantiating P := {Integer} (and T := String) on the first
  -- occurrence and substituting it at every later one. See the
  -- generic signatures section of signature_compatible for the exact
  -- unification rules (they mirror TypeVar: only a candidate-side
  -- ParamSpec instantiates; a super-side one stays universal).
  --
  -- Deliberate, documented scope of this first iteration:
  --
  -- - Type-level only. ParamSpec carries information for the
  --   is_subtype/signature_compatible relation over *declared* types;
  --   it is not enforced at call time. A Signature/Function rejects it
  --   (that wrapper enforces types on every call, which a deferred
  --   whole-list capture cannot express), and at the value level a
  --   Callable(P, {R}) treats parameters as unchecked for raw
  --   functions, exactly as AnyParams does.
  -- - Whole-list only. Like AnyParams, a ParamSpec stands in for the
  --   *entire* parameter list; it is rejected as a list entry, so
  --   leading fixed parameters (mypy's Concatenate,
  --   Callable(Concatenate(int, P), R)) cannot be spelled and are a
  --   future extension.
  -- - No P.args/P.kwargs projection (out of scope; Lua has no keyword
  --   arguments).
  -- - A captured list is stored verbatim, including a trailing VARARG
  --   ('...') tail or AnyParams-ness, and re-split on substitution.
  --   That trailing-tail boundary is the composition point for a
  --   future TypeVarTuple/Unpack analog (#104), which would bind the
  --   variadic tail a ParamSpec here captures wholesale.
  --
  -- Like AnyParams and Rest, a ParamSpec is not itself a type matcher
  -- (it has no __isinstance), so using it as one raises the standard
  -- non-matcher error; it is only valid in place of a Callable's
  -- parameter list. Two distinct ParamSpecs sharing a name are
  -- independent variables (identity, never name, decides), the same
  -- convention as TypeVar.
  if type(name) ~= 'string' then
    error('ParamSpec: expected a string name, got ' .. type(name), 2)
  end
  return setmetatable({
    [param_spec_mark] = true,

    __name = name,
  }, {
    __tostring = function(self)
      return self.__name
    end,
  })
end

Any=any_type_check()
Never=never_type_check()
Union=union_type_check
Optional=optional_type_check
Dict=dict_type_check
ListOf=list_of_type_check
SetOf=set_of_type_check
Protocol=protocol_type_check
Callable=callable_type_check
Iterator=iterator_type_check
Generator=generator_type_check
Tuple=tuple_type_check
Rest=rest_type_check
Literal=literal_type_check
NewType=new_type_check
ClassOf=class_of_type_check
Lazy=lazy_type_check
resolve_lazy=resolve_lazy_matcher
TypeVar=type_var_type_check
ParamSpec=param_spec_type_check
AnyParams=any_params_sentinel
-- These share their (local) implementation names, so the exports go
-- through _ENV explicitly (a bare assignment would just write the
-- local back to itself).
_ENV.is_rest=is_rest
_ENV.is_any_params=is_any_params
_ENV.is_param_spec=is_param_spec
_ENV.is_type_var=is_type_var
_ENV.matcher_kind=matcher_kind
_ENV.enter_type_var_scope=enter_type_var_scope
_ENV.exit_type_var_scope=exit_type_var_scope

return _M

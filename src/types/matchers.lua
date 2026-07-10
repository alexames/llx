-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx.core'
local environment = require 'llx.environment'

-- Load-bearing: TypeVar binding inference binds numbers to the
-- narrowest of these singletons (see infer_type_var_binding).
local Float = require 'llx.types.float' . Float
local Integer = require 'llx.types.integer' . Integer

-- TODO: I believe these can be removed.
local Boolean = require 'llx.types.boolean' . Boolean
local Function = require 'llx.types.function' . Function
local Nil = require 'llx.types.nil' . Nil
local Number = require 'llx.types.number' . Number
local String = require 'llx.types.string' . String
local Table = require 'llx.types.table' . Table
local Thread = require 'llx.types.thread' . Thread
local Userdata = require 'llx.types.userdata' . Userdata
local isinstance = require 'llx.isinstance' . isinstance
local Set = require 'llx.types.set' . Set

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

local function union_type_check(type_list)
  local expected_typenames = '{' .. Table.concat(type_list, ',') .. '}'
  local typename = 'Union' .. expected_typenames
  return setmetatable({
    __name = typename,

    type_list = type_list,

    __isinstance = function(self, value)
      for _, type_checker in ipairs(type_list) do
        if isinstance(value, type_checker) then
          return true
        end
      end
      return false
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
  local inner = type_or_list
  if type(type_or_list) == 'table'
      and type_or_list.__isinstance == nil then
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
  -- exposed shape and the checks below see only real fields.
  local declared = {}
  for k, v in pairs(fields) do
    if k ~= '__exact' then declared[k] = v end
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
  local typename = 'Dict<' .. type_name_of(key_type) ..
                   ', ' .. type_name_of(value_type) .. '>'
  return setmetatable({
    __name = typename,

    key_type = key_type,
    value_type = value_type,

    __isinstance = function(self, value)
      if type(value) ~= 'table' then return false end
      for k, v in pairs(value) do
        if not isinstance(k, key_type) then return false end
        if not isinstance(v, value_type) then return false end
      end
      return true
    end,
  }, {
    __tostring = function(self) return self.__name end,
  })
end

local function list_of_type_check(element_type)
  local typename = 'ListOf<' .. type_name_of(element_type) .. '>'
  return setmetatable({
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
  local typename = 'SetOf<' .. type_name_of(element_type) .. '>'
  return setmetatable({
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
      for element in pairs(value) do
        if not isinstance(element, element_type) then
          return false
        end
      end
      return true
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

-- Raises ValueException when a Rest(T) marker appears in a declared
-- type list that is not a Tuple element list. Rest carries no
-- __isinstance, so a signature position holding one could never
-- match any value; failing loudly at construction is the same policy
-- Callable already applies to a non-trailing VARARG. `where` names
-- the raising matcher in the message.
local function reject_rest_entries(type_list, where)
  for i = 1, #type_list do
    if is_rest(type_list[i]) then
      exceptions_module = exceptions_module or require 'llx.exceptions'
      error(exceptions_module.ValueException(
        where .. ': Rest(T) is only valid inside Tuple; use a '
        .. "trailing VARARG ('...') for variadic signatures", 3))
    end
  end
end

local function callable_type_check(param_types, return_types, options)
  param_types = param_types or {}
  return_types = return_types or {}
  options = options or {}
  local strict = options.strict == true

  -- A trailing VARARG ('...') entry in param_types declares that the
  -- callable accepts arbitrary extra arguments beyond the fixed,
  -- typed prefix, mirroring Signature's call-time semantics (see
  -- llx.check_arguments). Signature-wrapped values are handled by
  -- signature_compatible; the fixed prefix count computed here drives
  -- the raw-function arity checks below. Note that
  -- Callable({VARARG}, {R}) is not mypy's Callable[..., R] ("do not
  -- check parameters"): it requires the matched function to itself
  -- be declared variadic. An any-parameters escape hatch would be a
  -- separate feature.
  check_arguments_module =
      check_arguments_module or require 'llx.check_arguments'
  local vararg_marker = check_arguments_module.VARARG
  local params_fixed = #param_types
  local params_variadic = param_types[params_fixed] == vararg_marker
  if params_variadic then
    params_fixed = params_fixed - 1
  end
  -- A non-trailing VARARG can never be satisfied (check_returns_exact
  -- raises for it at call time), so fail loudly at construction
  -- rather than silently matching nothing.
  for i = 1, params_fixed do
    if param_types[i] == vararg_marker then
      error("Callable: VARARG ('...') must be the last entry in "
        .. 'the parameter list', 2)
    end
  end
  for i = 1, #return_types - 1 do
    if return_types[i] == vararg_marker then
      error("Callable: VARARG ('...') must be the last entry in "
        .. 'the return list', 2)
    end
  end
  -- Rest(T) is a Tuple-only marker (it has no __isinstance), so a
  -- parameter or return position holding one is silently
  -- unsatisfiable; reject it anywhere in either list. A *typed*
  -- variadic tail for signatures is a separate feature; the bare
  -- VARARG marker is the supported (unchecked) spelling.
  reject_rest_entries(param_types, 'Callable')
  reject_rest_entries(return_types, 'Callable')

  local param_names = {}
  for i, t in ipairs(param_types) do param_names[i] = type_name_of(t) end
  local return_names = {}
  for i, t in ipairs(return_types) do return_names[i] = type_name_of(t) end
  -- Strictness is part of the matcher's identity, so it is encoded in
  -- the name (which is_subtype falls back to when comparing matchers).
  local typename = 'Callable<(' .. table.concat(param_names, ', ')
                   .. ') -> (' .. table.concat(return_names, ', ') .. ')>'
                   .. (strict and ' strict' or '')

  local signature_module = nil
  local subtype_module = nil

  return setmetatable({
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
      -- available. The requires are deferred to avoid load-time cycles
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
      if type(value) == 'function' then
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
  -- - Raw functions carry no per-step type information, so they are
  --   accepted structurally (any function could be an iterator
  --   closure; generic-for's state/control arguments make arity
  --   heuristics meaningless here). This is the documented weak
  --   fallback; wrap the iterator (Yields{...} .. fn) to make the
  --   yield types checkable.
  -- - Other callables (tables or userdata with __call) are likewise
  --   accepted structurally.
  -- - Everything else -- including bare coroutine threads, which
  --   generic-for cannot drive -- is rejected.
  --
  -- The matcher never checks yielded values itself: per-step checking
  -- costs O(yield arity) on every loop iteration, so enforcement
  -- stays opt-in via the wrappers in llx.typed_iterators.
  local yield_count = select('#', ...)
  local yield_types = {...}
  check_arguments_module =
      check_arguments_module or require 'llx.check_arguments'
  local vararg_marker = check_arguments_module.VARARG
  for i = 1, yield_count do
    if yield_types[i] == nil then
      error('Iterator: yield type ' .. i .. ' is nil', 2)
    end
    if i < yield_count and yield_types[i] == vararg_marker then
      error("Iterator: VARARG ('...') must be the last entry in "
        .. 'the yield type list', 2)
    end
  end
  local yield_names = {}
  for i = 1, yield_count do
    yield_names[i] = type_name_of(yield_types[i])
  end
  local typename = 'Iterator<' .. table.concat(yield_names, ', ')
                   .. '>'

  -- Cached upvalues for deferred requires (the Callable pattern:
  -- llx.typed_iterators and llx.is_subtype depend on this module, so
  -- requiring them at load time would cycle).
  local typed_iterators_module = nil
  local subtype_module = nil

  return setmetatable({
    __name = typename,

    -- Expose the per-step yield types so callers can introspect.
    yields = yield_types,

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
          -- signature_compatible on returns-only signatures.
          subtype_module = subtype_module or require 'llx.is_subtype'
          return subtype_module.signature_compatible(
              {returns = value.yields}, {returns = yield_types})
        end
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
  -- Generator{yields=, accepts=, returns=}: matches typed coroutine
  -- generators by declared contract -- the runtime analog of mypy's
  -- Generator[YieldType, SendType, ReturnType]. Each list is optional
  -- (defaulting to empty); a trailing VARARG ('...') entry declares
  -- an unchecked variadic tail.
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
      .. 'yields, accepts, and returns lists', 2)
  end
  for key in pairs(contract) do
    if key ~= 'yields' and key ~= 'accepts' and key ~= 'returns' then
      error("Generator: unknown contract key '" .. tostring(key)
        .. "'", 2)
    end
  end
  local yields = contract.yields or {}
  local accepts = contract.accepts or {}
  local returns = contract.returns or {}
  local function names_of(types)
    local names = {}
    for i, t in ipairs(types) do names[i] = type_name_of(t) end
    return table.concat(names, ', ')
  end
  -- The full contract is part of the matcher's identity, so it is
  -- encoded in the name (which is_subtype falls back to when
  -- comparing matchers).
  local typename = 'Generator<yields=(' .. names_of(yields)
                   .. '), accepts=(' .. names_of(accepts)
                   .. '), returns=(' .. names_of(returns) .. ')>'

  -- Cached upvalues for deferred requires; see Iterator above.
  local typed_iterators_module = nil
  local subtype_module = nil

  return setmetatable({
    __name = typename,

    -- Expose the contract so callers (and generator_compatible) can
    -- introspect.
    yields = yields,
    accepts = accepts,
    returns = returns,

    __isinstance = function(self, value)
      if type(value) == 'thread' then
        -- Weak structural fallback: it is a coroutine, but its
        -- contract is unknowable at runtime.
        return true
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
      error("Tuple: '...' and Rest(T) must be the last entry in "
        .. 'the element type list', 2)
    end
  end
  local element_names = {}
  for i = 1, fixed_count do
    element_names[i] = type_name_of(element_types[i])
  end
  -- The variadic tail is part of the matcher's identity, so it is
  -- encoded in the name (which is_subtype falls back to when
  -- comparing matchers), with distinct spellings for the unchecked
  -- ('...') and typed ('...T') forms.
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
  -- an uninhabitable type with no base case; it cannot be detected at
  -- resolution time and diverges at check time, like any other
  -- unbounded recursion in user code.
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
  -- - Binding is first-witness, one-pass: there is no constraint
  --   solving or join, so with params={T, T} the call f(cat, animal)
  --   is rejected while f(animal, cat) is accepted (the second value
  --   is checked against the first one's binding with isinstance,
  --   which admits subclass instances). Likewise f(1, 1.5) is
  --   rejected: 1 binds T to Integer, not Number.
  -- - Binding is also one-pass in that there is no rollback: a
  --   matcher branch that ultimately fails (a Union member, or a
  --   container that rejects a later element) may still have
  --   recorded a binding for a variable it touched, and that binding
  --   persists for the rest of the call. E.g. Union{ListOf(T), Any}
  --   can bind T from a list the ListOf branch then rejects, so a
  --   call accepted through the Any member is still constrained by
  --   that binding, and results can depend on Union member order.
  --   Keep TypeVars out of union alternatives that are expected to
  --   fail over.
  -- - The witness is the first value *checked*: positional params
  --   and ipairs-ordered containers (ListOf, Tuple) bind
  --   deterministically, but pairs-iterated containers (Dict, SetOf)
  --   reach an arbitrary element first, so a container whose
  --   elements mix a class with its subclasses may bind
  --   nondeterministically.
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
  -- - Type-level relations do not learn TypeVars in this iteration:
  --   llx.is_subtype relates a TypeVar only to itself (and to Any, as
  --   every type is), so signature_compatible -- and therefore the
  --   Callable matcher -- conservatively rejects a generic signature
  --   against a concrete one. ParamSpec/TypeVarTuple analogs are
  --   follow-ups.
  -- - Like NewType, the matcher's __name is the given name, and
  --   is_subtype compares *containers* by name: two ListOf(T)s built
  --   from distinct TypeVars both named 'T' compare equal at the
  --   type level (bare TypeVars are protected by the identity rule
  --   above). Keep TypeVar names unique where that matters.
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
      return type_var_consistent(value, binding)
    end,
  }, {
    __tostring = function(self)
      return self.__name
    end,
  })
  return var
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
-- These share their (local) implementation names, so the exports go
-- through _ENV explicitly (a bare assignment would just write the
-- local back to itself).
_ENV.is_rest=is_rest
_ENV.is_type_var=is_type_var
_ENV.enter_type_var_scope=enter_type_var_scope
_ENV.exit_type_var_scope=exit_type_var_scope

return _M

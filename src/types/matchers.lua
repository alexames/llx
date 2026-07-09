-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx.core'
local environment = require 'llx.environment'

-- TODO: I believe these can be removed.
local Boolean = require 'llx.types.boolean' . Boolean
local Function = require 'llx.types.function' . Function
local Integer = require 'llx.types.integer' . Integer
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
      -- Accept any array-like table: plain array tables and
      -- llx.List instances alike (List stores its elements in the
      -- array part, so ipairs works on both). Nominal checking is
      -- already available via isinstance(value, List). Like Dict,
      -- the check walks every element, so each isinstance call is
      -- O(n) in the length of the list.
      if type(value) ~= 'table' then return false end
      for _, element in ipairs(value) do
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

local function set_of_type_check(element_type)
  local typename = 'SetOf<' .. type_name_of(element_type) .. '>'
  return setmetatable({
    __name = typename,

    -- Expose the element type so callers can introspect.
    element_type = element_type,

    __isinstance = function(self, value)
      -- Require an actual llx.Set instance; a plain table used as a
      -- raw key-set can already be expressed as Dict(T, Boolean).
      -- Iterating a Set (via its __pairs metamethod) yields
      -- element -> true, so the elements are the keys. Like Dict,
      -- each isinstance call is O(n) in the size of the set.
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

-- Cached upvalue for the deferred require of llx.check_arguments
-- (deferred to avoid a load-time cycle: llx.check_arguments depends,
-- through llx.getclass, on llx.types and therefore on this module).
local check_arguments_module = nil

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
      -- llx.is_subtype.signature_compatible. Variance applies in both
      -- lenient and strict mode: signature_compatible already enforces
      -- sound arity rules, and strict's extra constraints exist for
      -- raw functions, where no declared types are available. The
      -- requires are deferred to avoid load-time cycles (llx.signature
      -- and llx.is_subtype depend, indirectly, on llx.types) and
      -- cached in upvalues.
      signature_module = signature_module or require 'llx.signature'
      if type(value) == 'table'
          and isinstance(value, signature_module.Function) then
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

local function tuple_type_check(element_types)
  if type(element_types) ~= 'table' then
    error('Tuple: expected a list of element types', 2)
  end
  local element_names = {}
  for i, t in ipairs(element_types) do
    element_names[i] = type_name_of(t)
  end
  local typename = 'Tuple<' .. table.concat(element_names, ', ') .. '>'
  return setmetatable({
    __name = typename,

    -- Expose the positional type list so callers can introspect.
    element_types = element_types,

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
      if #value ~= #element_types then return false end
      for i, expected_type in ipairs(element_types) do
        if not isinstance(value[i], expected_type) then
          return false
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

local function describe_value(value)
  local value_type = type(value)
  if value_type == 'number' or value_type == 'boolean' then
    return value_type .. ' ' .. tostring(value)
  end
  if value_type == 'string' then
    return "string '" .. value .. "'"
  end
  return value_type
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

Any=any_type_check()
Never=never_type_check()
Union=union_type_check
Optional=optional_type_check
Dict=dict_type_check
ListOf=list_of_type_check
SetOf=set_of_type_check
Protocol=protocol_type_check
Callable=callable_type_check
Tuple=tuple_type_check
Literal=literal_type_check
NewType=new_type_check

return _M

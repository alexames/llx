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
  -- Capture field names for the type name; sort for stability.
  local field_names = {}
  for k in pairs(fields) do field_names[#field_names + 1] = k end
  table.sort(field_names, function(a, b)
    return tostring(a) < tostring(b)
  end)
  local typename = 'Protocol{' .. table.concat(field_names, ', ') .. '}'
  return setmetatable({
    __name = typename,

    -- Expose the shape so callers can introspect.
    fields = fields,

    __isinstance = function(self, value)
      if type(value) ~= 'table' then return false end
      for field_name, expected_type in pairs(fields) do
        if not isinstance(value[field_name], expected_type) then
          return false
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

-- Compares two type checkers for the purposes of signature matching.
-- Type checkers match when they are the same object, when both expose
-- the same __name (so two separately constructed matchers such as
-- Dict(String, Integer) compare equal), or when one side is a string
-- type name (Signature declarations may name a type by string, as
-- supported by check_arguments) equal to the other side's __name.
-- Anonymous classes share a placeholder __name, so they only ever
-- match by identity.
--
-- TODO(#26): replace exact matching with the signature-compatibility
-- relation (variance rules) once it exists.
local anonymous_class_name = '<anonymous class>'

local function same_type(a, b)
  if rawequal(a, b) then return true end
  if type(a) == 'string' and type(b) == 'table' then
    return a == b.__name
  end
  if type(b) == 'string' and type(a) == 'table' then
    return b == a.__name
  end
  if type(a) == 'table' and type(b) == 'table' then
    local a_name = a.__name
    return a_name ~= nil
       and a_name ~= anonymous_class_name
       and a_name == b.__name
  end
  return false
end

local function same_type_list(expected, actual)
  if type(actual) ~= 'table' then return false end
  if #expected ~= #actual then return false end
  for i = 1, #expected do
    if not same_type(expected[i], actual[i]) then return false end
  end
  return true
end

local function callable_type_check(param_types, return_types, options)
  param_types = param_types or {}
  return_types = return_types or {}
  options = options or {}
  local strict = options.strict == true

  local param_names = {}
  for i, t in ipairs(param_types) do param_names[i] = type_name_of(t) end
  local return_names = {}
  for i, t in ipairs(return_types) do return_names[i] = type_name_of(t) end
  -- Strictness is part of the matcher's identity, so it is encoded in
  -- the name (which same_type falls back to when comparing matchers).
  local typename = 'Callable<(' .. table.concat(param_names, ', ')
                   .. ') -> (' .. table.concat(return_names, ', ') .. ')>'
                   .. (strict and ' strict' or '')

  local signature_module = nil

  return setmetatable({
    __name = typename,

    -- Expose the signature so other matchers can introspect.
    params = param_types,
    returns = return_types,
    strict = strict,

    __isinstance = function(self, value)
      -- Signature-wrapped functions declare their parameter and return
      -- types, so compare the declared signature directly. The require
      -- is deferred to avoid a load-time cycle (llx.signature depends,
      -- indirectly, on llx.types) and cached in an upvalue.
      signature_module = signature_module or require 'llx.signature'
      if type(value) == 'table'
          and isinstance(value, signature_module.Function) then
        return same_type_list(param_types, value.params)
           and same_type_list(return_types, value.returns)
      end
      -- Raw functions carry no type information; arity (via
      -- debug.getinfo) is the strongest available check. By default the
      -- check is lenient: a vararg function can satisfy any parameter
      -- list, and a function declaring fewer parameters than the
      -- signature simply ignores the extra arguments (idiomatic Lua).
      -- With options.strict, the declared arity must match exactly and
      -- varargs are rejected. Note that debug.getinfo reports every C
      -- function as vararg with nparams == 0, so lenient mode accepts
      -- any C function and strict mode rejects them all.
      if type(value) == 'function' then
        local info = debug.getinfo(value, 'u')
        if strict then
          return not info.isvararg and info.nparams == #param_types
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

Any=any_type_check()
Union=union_type_check
Optional=optional_type_check
Dict=dict_type_check
Protocol=protocol_type_check
Callable=callable_type_check
-- Tuple=tuple_type_check

return _M

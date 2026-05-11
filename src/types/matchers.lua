-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

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

local _ENV, _M = environment.create_module_environment()

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
  local function name_of(t)
    return t and (t.__name or tostring(t)) or 'nil'
  end
  local typename = 'Dict<' .. name_of(key_type) ..
                   ', ' .. name_of(value_type) .. '>'
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

Any=any_type_check()
Union=union_type_check
Optional=optional_type_check
Dict=dict_type_check
Protocol=protocol_type_check
-- Tuple=tuple_type_check

return _M

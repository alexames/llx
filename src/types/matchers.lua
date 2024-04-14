-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'

-- TODO: I believe these can be removed.
local Boolean = require 'llx/src/types/boolean' . Boolean
local Function = require 'llx/src/types/function' . Function
local Integer = require 'llx/src/types/integer' . Integer
local Nil = require 'llx/src/types/nil' . Nil
local Number = require 'llx/src/types/number' . Number
local String = require 'llx/src/types/string' . String
local Table = require 'llx/src/types/table' . Table
local Thread = require 'llx/src/types/thread' . Thread
local Userdata = require 'llx/src/types/userdata' . Userdata
local isinstance = require 'llx/src/isinstance' . isinstance

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

local function optional_type_check(type_checker)
  return union_type_check{Nil, type_checker[1]}
end

local function dict_type_check(type_checker)
end

Any=any_type_check()
Union=union_type_check
Optional=optional_type_check
Dict=dict_type_check
-- Tuple=tuple_type_check

return _M

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx/src/environment'
local List = require 'llx/src/types/list' . List
local exceptions = require 'llx/src/exceptions'
local getclass = require 'llx/src/getclass' . getclass
local isinstance = require 'llx/src/isinstance' . isinstance

local _ENV, _M = environment.create_module_environment()

local function check_field(schema, value, path, level)
  local schema_type = schema.type

  if schema_type == nil then
    error('nil schema type', 5)
  end

  -- Validate that the value is of the correct type.
  if not isinstance(value, schema_type) then
    return false, exceptions.SchemaFieldTypeMismatchException(
        path, schema_type, getclass(value), level + 1)
  end

  -- Validate that the per-type schema check passes.
  local __validate = schema_type.__validate

  if __validate then
    local successful, exception =
        __validate(value, schema, path, level + 1, check_field)
    if not successful then
      return successful, exception
    end
  end

  return true
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function matches_schema(schema, value, nothrow)
  local successful, exception = check_field(schema, value, {}, 2)
  if successful then
    return true
  else
    if nothrow then
      return false, exception
    else
      error(exception)
    end
  end
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
function Schema(schema)
  function schema:__isinstance(value)
    return matches_schema(schema, value, true)
  end

  schema.__name = schema.__name or schema.title or 'Schema'
  setmetatable(schema, {__tostring=function(self) return self.__name end})

  return schema
end

return _M

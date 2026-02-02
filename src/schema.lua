-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local getclass_module = require 'llx.getclass'
local isinstance_module = require 'llx.isinstance'
local list = require 'llx.types.list'

local _ENV, _M = environment.create_module_environment()

local getclass = getclass_module.getclass
local isinstance = isinstance_module.isinstance
local List = list.List

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

--- Checks if a value matches a schema.
-- @param schema The schema to validate against
-- @param value The value to validate
-- @param nothrow If true, returns false on mismatch instead of throwing
-- @return true if valid, or false and exception if nothrow is true
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

--- Creates a schema object for type validation.
-- @param schema The schema definition table
-- @return The schema object with isinstance support
function Schema(schema)
  function schema:__isinstance(value)
    return matches_schema(schema, value, true)
  end

  schema.__name = schema.__name or schema.title or 'Schema'
  setmetatable(schema, {__tostring=function(self) return self.__name end})

  return schema
end

return _M

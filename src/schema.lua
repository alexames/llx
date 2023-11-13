require 'llx/src/types/list'
require 'llx/src/exceptions'
require 'llx/src/getclass'
require 'llx/src/isinstance'

local function check_field(schema, value, path, level)
  local schema_type = schema.type

  -- Validate that the value is of the correct type.
  if not isinstance(value, schema_type) then
    return false, SchemaFieldTypeMismatchException(
        path, schema_type, getclass(value), level + 1)
  end

  -- Validate that the per-type schema check passes.
  local __schema_validate = getclass(value).__schema_validate

  if __schema_validate then
    local successful, exception =
        __schema_validate(value, schema, path, level + 1, check_field)
    if not successful then
      return successful, exception
    end
  end

  return true
end

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

function Schema(schema)
  function schema:__isinstance(value)
    return matches_schema(schema, value, true)
  end

  schema.__name = schema.__name or schema.title or 'Schema'

  return schema
end

return {
  Schema=Schema,
  matches_schema=matches_schema,
}

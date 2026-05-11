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

--- Checks type-agnostic constraint fields (one_of, predicate)
-- against a value that has already passed type and per-type
-- __validate checks. Type-specific constraints like minimum,
-- maximum, multiple_of (Number), min_length, max_length, pattern
-- (String), and properties, required (Table) are handled by the
-- corresponding type's own __validate hook.
-- @param value The value to constrain
-- @param schema The schema with optional constraint fields
-- @param path Dotted-key path for error reporting
-- @param level Stack level offset for traceback
-- @return true on success, or (false, SchemaConstraintFailureException)
local function check_constraints(value, schema, path, level)
  -- one_of: enum-like restriction to a fixed set of allowed values.
  if schema.one_of ~= nil then
    local found = false
    for _, allowed in ipairs(schema.one_of) do
      if value == allowed then
        found = true
        break
      end
    end
    if not found then
      local parts = {}
      for _, v in ipairs(schema.one_of) do
        parts[#parts + 1] = tostring(v)
      end
      return false, exceptions.SchemaConstraintFailureException(
          path,
          string.format('value %s is not one of: %s',
                        tostring(value), table.concat(parts, ', ')),
          level + 1)
    end
  end

  -- predicate: arbitrary callback returning truthy on accept.
  -- It may return (false, message) to supply a custom error.
  if schema.predicate ~= nil then
    local result, msg = schema.predicate(value)
    if not result then
      return false, exceptions.SchemaConstraintFailureException(
          path,
          msg or string.format('value %s failed predicate',
                               tostring(value)),
          level + 1)
    end
  end

  return true
end

local function check_field(schema, value, path, level)
  local schema_type = schema.type

  if schema_type == nil then
    error('nil schema type', 5)
  end

  -- Validate that the value is of the correct type.
  if not isinstance(value, schema_type) then
    return false, exceptions.SchemaFieldTypeMismatchException(
        path, schema_type, getclass(value), value, level + 1)
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

  -- Validate scalar constraint fields (min/max/length/pattern/etc).
  return check_constraints(value, schema, path, level)
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
-- The returned schema is a new table; the input is not mutated.
-- Passing the same definition to Schema twice produces two
-- independent wrappers.
-- @param definition The schema definition table (type, title,
--   constraints, etc.)
-- @return The schema object with isinstance support
function Schema(definition)
  -- Shallow-copy so we don't pollute the caller's table with
  -- __isinstance, __name, or a metatable. Constraint tables and
  -- nested Schemas are shared by reference, which is fine because
  -- those are themselves immutable wrappers or value-typed.
  local wrapper = {}
  for k, v in pairs(definition) do
    wrapper[k] = v
  end

  function wrapper:__isinstance(value)
    return matches_schema(wrapper, value, true)
  end

  wrapper.__name = wrapper.__name or wrapper.title or 'Schema'
  setmetatable(wrapper, {
    __tostring = function(self) return self.__name end,
  })

  return wrapper
end

return _M

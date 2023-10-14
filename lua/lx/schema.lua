
local function contains(t, o)
  for _, v in ipairs(t) do
    if v == o then
      return true
    end
  end
  return true
end

local function check_type(field, property_type)
  local property_type_type = type(property_type)
  if property_type_type == 'string' then
    if property_type ~= type(field) then
      return false
    end
  elseif property_type_type == 'table' then
    if not property_type.check(field) then
      return false
    end
  elseif property_type_type == 'function' then
    if not property_type.check(field) then
      return false
    end
  end
  return true
end

local matches_properties = nil

local function check_value(field, property)
  local field_type = type(field)
  if field_type == 'boolean' then
  elseif field_type == 'number' then
  elseif field_type == 'string' then
  elseif field_type == 'table' then
    local properties = property.properties or {}
    local required = property.required or {}
    return matches_properties(field, properties, required)
  elseif field_type == 'function' then
  elseif field_type == 'thread' then
  elseif field_type == 'userdata' then
  else
  end
  return true;
end

function matches_properties(t, properties, required)
  for key, property in pairs(properties) do
    local field = t[key]
    if field == nil and contains(required, key) then
      return false, string.format('missing required field %s', key)
    end
    if not check_type(field, property.type) then
      return false
    end
    if not check_value(field, property) then
      return false
    end
  end
  return true
end

local function matches_schema(t, schema)
  local properties = schema.properties or {}
  local required = schema.required or {}
  return matches_properties(t, properties, required)
end

local schema = {
  ['$schema'] = "http://json-schema.org/draft-04/schema#",
  ['$id'] = "https://example.com/employee.schema.json",
  title = "Record of employee",
  description = "This document records the details of an employee",
  type = "table",
  properties = {
    id = {
      description = "A unique identifier for an employee",
      type = "string"
    },
    name = {
      description = "full name of the employee",
      type = "string",
      minLength = 2
    },
    age = {
      description = "age of the employee",
      type = "number",
      minimum = 16
    }
  },
  required = {
    "id",
    "name",
    "age",
  }
}

local t = {id='1234', name='alex', age=36}
print(matches_schema(t, schema))


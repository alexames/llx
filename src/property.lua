-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class
local Decorator = decorator.Decorator

--- Tries to retrieve a property from the class table or its superclasses.
--
-- This function attempts to retrieve the value of a property from the class
-- table or its superclasses. It traverses through the inheritance hierarchy
-- and returns the value if found, otherwise returns nil.
--
-- @param class_table The class table to check for properties
-- @param t The instance table from which to get the property value
-- @param k The key of the property to retrieve
-- @return The value of the property if found, otherwise nil
local function try_get_property(class_table, t, k)
  -- Is this a property?
  local properties = class_table.__properties
  local property = properties[k]
  if property then
    return property.get(t)
  end

  if class_table.__superclasses then
    for _, base in ipairs(class_table.__superclasses) do
      local value = try_get_property(base, t, k)
      if value ~= nil then
        return value
      end
    end
  end
end

--- Tries to set a property in the class table or its superclasses.
--
-- This function attempts to set a property in the class table or its
-- superclasses. It first checks if the property exists in the class table's
-- `__properties` table. If the property is found, it invokes the property's
-- setter function, if available, to set the value in the instance table. If
-- the property is not found in the class table, it recursively checks the
-- superclasses' properties.
--
-- @param class_table The class table to check for properties
-- @param t The instance table to set the property in
-- @param k The key of the property to set
-- @param v The value to set
-- @return True if the property was set successfully, otherwise false
local function try_set_property(class_table, t, k, v)
  local properties = class_table.__properties
  local property = properties[k]
  if property then
    assert(type(property) == 'table')
    property.set(t, v)
    return true
  end
  return false
end

--- Treat a getter/setter pair on a table as a field.
Property = class 'Property' : extends(Decorator) {
  decorate = function(self, class_table, name, value)
    local properties = class_table.__properties
    if properties == nil then
      properties = {}
      class_table.__properties = properties
      local old_index = class_table.__index
      local old_newindex = class_table.__newindex or rawset
      class_table.__index = function(t, k)
        return try_get_property(class_table, t, k) or old_index(t, k)
      end
      class_table.__newindex = function(t, k, v)
        if not try_set_property(class_table, t, k, v) then
          old_newindex(t, k, v)
        end
      end
    end
    return properties, name, value
  end,
}
property = Property()

return _M

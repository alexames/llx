-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

-- A class is a designed to mimic class-like behavior from other languages in
-- Lua. It provides a syntacticaly similar method of initializing the class
-- definition, and allows for basic inheritance.
--
-- A class can be created as follows:
--
--     local Line = class 'Line' {
--       __init = function(self, length)
--         self._length = length
--       end,
--
--       get_length = function(self)
--         return self._length
--       end,
--     }
--
-- The result is that the table Line now contains all the functions and members
-- in the class definition. Instances of the class can be instantiated like so:
--
--     f = Line(100)
--
-- (This is because the class definition itself has a `__call` metamethod)
--
-- # Initializer
--
-- The "__init" function serves as the class initializer, invoked automatically
-- when creating instances. It initializes class members and sets up the initial
-- state of the object.
--
-- # Inheritance
--
-- Classes also support inheritance:
--
--     local Rectangle = class 'Rectangle' : extends(Line) {
--       __init = function(self, length, width)
--         self.Line.__init(self, length)
--         self.width = width
--       end,
--
--       get_width = function(self)
--         return self.width
--       end,
--
--       get_area = function(self)
--         return self.width * self.length
--       end,
--     }
--
-- This Rectangle class inherits the values and functions from the Line
-- superclass. Additionally, when inheriting from a class, a reference to that
-- class is added to the class definition automatically.
--
-- # Properties
--
-- Classes also support Properties. That is, fields that look like look like
-- a normal field but that are backed by getter and setter functions.
--
--     local Rectangle = class 'Rectangle' : extends(Line) {
--       __init = function(self, length, width)
--         self.Line.__init(self, length)
--         self._width = width
--       end,
--
--       ['width' | property] = {
--         set = function(self, value)
--           self._width = value
--         end,
--         get = function(self)
--           return self._width
--         end,
--       }
--
--       ['area' | property] = {
--         get = function(self)
--            return self._width * self._length
--         end,
--       }
--     }
--
-- # Anonymous classes
--
-- TODO
--
-- # Conversion operators
--
-- TODO
--
-- # Implementation details
-- TODO
-- ## Proxy Class Tables
-- TODO
-- ## Superclass metafield
-- TODO
-- ## Index and Default Index metafield
-- TODO
-- ## Internal Index metafield
-- TODO

--------------------------------------------------------------------------------
-- Utilities

-- TODO: remove this, make this file have no dependencies
local core = require 'llx/src/core'
local getmetafield = core.getmetafield

--- Tries to set a metafield in a class table if it does not already exist.
--
-- This function attempts to set a metafield in a class table only if the
-- specified metafield does not already exist. If the metafield exists, it does
-- nothing.
--
-- @param class_table The class table in which to set the metafield
-- @param key The key of the metafield to set
-- @param value The value to set for the metafield
local function try_set_metafield(class_table, key, value)
  if class_table.__metafields[key] == nil then
    rawset(class_table, key, value)
  end
end

--- Tries to set a metafield on subclasses of a given class table.
--
-- This function iterates through the subclasses of a given class table and
-- tries to set a metafield on each subclass. It calls the `try_set_metafield`
-- function for each subclass to attempt to set the metafield.
--
-- @param class_table The class table whose subclasses to set the metafield on
-- @param key The key of the metafield to set
-- @param value The value to set for the metafield
local function try_set_metafield_on_subclasses(class_table, key, value)
  for _, subclass in pairs(class_table.__subclasses) do
    try_set_metafield(subclass, key, value)
  end
end

--- Handles potential metafield assignment on a class table.
--
-- This function checks if the provided key is a potential metafield (i.e.,
-- starts with '__') and assigns the given value to it in the class table's
-- `__metafields` table if the metafield is not already defined. Additionally,
-- it attempts to set the same metafield on all subclasses of the class table
-- using the `try_set_metafield_on_subclasses` function.
--
-- @param class_table The class table to handle the potential metafield
--                    assignment for
-- @param key The key of the potential metafield
-- @param value The value to assign to the potential metafield
local function handle_potential_metafield(class_table, key, value)
  -- Assign metafield value to class_table[key] if and only if
  -- class_table.__metafields does not define it.
  if type(key) == 'string' and key:sub(1, 2) == '__' then
    class_table.__metafields[key] = value
    try_set_metafield_on_subclasses(class_table, key, value)
  end
end

--- Checks if a class table is an instance of a given metatable or one of its
--- superclasses.
--
-- This function recursively checks if a class table is an instance of a given
-- metatable or one of its superclasses. It traverses through the inheritance
-- hierarchy and returns true if the class table matches the metatable or any
-- of its superclasses, otherwise returns false.
--
-- @param metatable The metatable to check against
-- @param class_table The class table to check
-- @return True if the class table is an instance of the metatable or one of its
--         superclasses, otherwise false
local function isinstance_impl(metatable, class_table)
  if metatable == class_table then
    return true
  end
  local superclasses = metatable and metatable.__superclasses
  if superclasses then
    for i, superclass in pairs(superclasses) do
      if isinstance_impl(superclass, class_table) then
        return true
      end
    end
  end
  return false
end

--------------------------------------------------------------------------------

local anonymous_class_name = '<anonymous class>'

--- Creates a class definer for defining Lua classes with inheritance.
--
-- This function creates a class definer object that facilitates the definition
-- of Lua classes, including inheritance. The returned class definer object
-- supports syntax such as:
--    class 'ClassName' { ... }
-- or
--    class 'DerivedClass' : extends(BaseClass) { ... }
--
-- The class definer object returned by this function allows for specifying
-- inheritance from one or more base classes using the 'extends' method.
-- Additionally, it enables the definition of properties and methods for
-- the class.
--
-- @param class_table The table representing the class
-- @param class_table_proxy Proxy table for the class
-- @return A class definer object for defining Lua classes
local function create_class_definer(class_table, class_table_proxy)
  local class_definer = nil
  class_definer = {
    extends = function(self, ...)
      local arg = {...}
      assert(#arg > 0, '%s must list at least one base class when extending')
      for i, base in ipairs(arg) do
        assert(type(base) == 'table', 
               string.format('%s must inherit from table, not %s',
                             class_table.__name, type(base)))
        local base_name = base.__name
        if base_name then
          class_table[base_name] = base
        end

        -- Bi-directional extends/extendedby bookkeeping.
        class_table.__superclasses[i] = base
        local extendedby = base.__subclasses
        if extendedby then
          extendedby[class_table.__name] = class_table_proxy
        end
      end

      return class_definer
    end
  }

  local class_definer_metatable = {
    __call = function(self, class_definition)
      for k, v in pairs(class_definition) do
        -- change this to a check to see if the key is a function
        if k.__isdecorator then
          local target_table, name, value = class_table_proxy, k.name, v
          for i, decorator in ipairs(k.decorator_table) do
            target_table, name, value =
              decorator:decorate(target_table, name, value)
          end
          target_table[name] = value
        else
          rawset(class_table, k, v)
          handle_potential_metafield(class_table, k, v)
        end
      end
      for _, superclass in ipairs(class_table.__superclasses) do
        for k, v in pairs(superclass.__metafields or {}) do
          try_set_metafield(class_table, k, v)
        end
      end
      return class_table_proxy
    end
  }

  setmetatable(class_definer, class_definer_metatable)
  return class_definer
end

--- Creates a proxy for the class table to manage instantiation and access.
--
-- This function creates a proxy for the class table to handle instance
-- creation, property access, and iteration. It sets up various metamethods to
-- initialize instances, handle property access and modification, and enable
-- iteration over class members. Additionally, it ensures that instances of the
-- proxy are distinct from the original class table.
--
-- @param class_table The class table to create a proxy for
-- @return The created class table proxy
local function create_class_table_proxy(class_table)
  local function class_table_next(unused, index)
    return next(class_table, index)
  end

  local class_table_proxy = {}
  local class_table_proxy_metatable = {
    __metatable = class_table_proxy;

    -- Used to initialize an instance of the class.
    __call = function(self, ...)
      local object = setmetatable(
        class_table.__new and class_table.__new(...) or {},
        class_table)
      if class_table.__init then
        class_table.__init(object, ...)
      end
      return object
    end;

    __index = class_table.__index;

    __newindex = function(self, k, v)
      rawset(class_table, k, v)
      handle_potential_metafield(class_table, k, v)
    end;

    __pairs = function()
      return class_table_next, nil, nil
    end;

    __len = function()
      return #class_table
    end;

    __eq = function(lhs, rhs)
      local other = (rawequal(class_table_proxy, lhs) and rhs or lhs)
      return rawequal(class_table, other)
    end;

    __tostring = function(self)
      return self.__name
    end,

    __name = class_table.__name,
  }
  return setmetatable(class_table_proxy, class_table_proxy_metatable)
end

--- Creates an internal table for managing class properties and inheritance.
--
-- This function creates an internal class table used for managing class
-- properties, inheritance relationships, and instance checking. It sets up
-- various metamethods for property access (`__index` and `__newindex`),
-- inheritance resolution (`__isinstance`), and default behavior
-- (`__internalindex`, `__defaultindex`). Additionally, it initializes internal
-- fields for storing properties, superclasses, subclasses, and metafields.
--
-- @param name The name of the class
-- @return The created internal class table
local function create_internal_class_table(name)
  local class_table = nil

  --- Tries to retrieve the value of a field from the superclasses.
  --
  -- This function attempts to retrieve the value of a field from the
  -- superclasses of the class table. It checks each superclass in order and
  -- returns the value of the field if found, otherwise returns nil.
  --
  -- @param k The key of the field to retrieve
  -- @return The value of the field if found, otherwise nil
  local function try_get_superclass_value(k)
    -- Do any of the base classes have the field?
    if class_table.__superclasses then
      for _, base in ipairs(class_table.__superclasses) do
        local value = base[k]
        if value then return value end
      end
    end
    return nil
  end

  --- Metamethod for indexing class instances.
  --
  -- This metamethod is invoked when attempting to access a field or property
  -- of a class instance. It first tries to retrieve the value from properties,
  -- then from the class table itself, and finally from the superclasses.
  --
  -- @param t The instance table
  -- @param k The key of the field or property to retrieve
  -- @return The value of the field or property if found, otherwise nil
  local function __index(t, k)
    return rawget(class_table, k) or try_get_superclass_value(k)
  end

  --- Checks if an object is an instance of the class.
  --
  -- This function checks if an object is an instance of the class represented
  -- by the internal class table. It traverses through the inheritance
  -- hierarchy to determine if the object is an instance of any of the
  -- superclasses.
  --
  -- @param self The internal class table
  -- @param o The object to check
  -- @return True if the object is an instance of the class, otherwise false
  local function __isinstance(self, o)
    return isinstance_impl(getmetatable(o), class_table)
  end

  -- Initialize the class table with internal fields and metamethods
  class_table = {
    __name = name;

    __superclasses = {};
    __subclasses = {};
    __metafields = {};

    __internalindex = __internalindex;
    __index = __index;
    __defaultindex = __index;

    __isinstance = __isinstance;
  }

  return class_table
end

--- Metatable for defining and instantiating classes.
--
-- This metatable is used for defining and instantiating classes. It defines a
-- `__call` metamethod, which is invoked when the metatable is called like a
-- function. Depending on the argument provided, it either defines a new class
-- or instantiates an existing class.
--
-- @param self The metatable object
-- @param name_or_definition The name of the class or a table containing the
--                           class definition
-- @return A class definer object for defining a new class, or an instance of
--         the specified class

local function class_argument_resolver(name_or_definition)
  local name = nil
  local class_definition = nil
  if type(name_or_definition) == 'string' then
    name = name_or_definition
    class_definition = nil
  else
    name = anonymous_class_name
    class_definition = name_or_definition
  end
  return name, class_definition
end

--- Creates a conversion function for instances of a class.
--
-- This function creates a conversion function for instances of a class to
-- convert them to instances of another class. It sets up a function `to_class`
-- that attempts to retrieve a metamethod named `__to_class` or
-- `__to_<classname>` from the object's metatable. If found, it invokes the
-- metamethod to perform the conversion.
--
-- @param name The name of the class
-- @param class_table The class table of the original class
-- @param class_table_proxy The proxy table for the original class
local function create_conversion_function(name, class_table, class_table_proxy)
  local to_class
  if name == anonymous_class_name then
    function to_class(value)
      local __to_class = getmetafield(value, class_table_proxy)
      return __to_class and __to_class(value)
    end
    class_table.to_class = to_class
  else
    local __to_class_key = '__to_' .. name
    function to_class(value)
      local __to_class = getmetafield(value, __to_class_key)
                         or getmetafield(value, class_table_proxy)
      return __to_class and __to_class(value)
    end
    class_table.to_class = to_class
    class_table['to_' .. name] = to_class
  end
end

--- Creates a new Lua class.
--
-- This function creates a new Lua class with the given name. It internally
-- generates the class table and its proxy, sets up conversion functions, and
-- locks down the class table to prevent direct modification. The class table
-- and its proxy are returned for further manipulation and instantiation.
--
-- @param name The name of the class
-- @return The created class table and its proxy
local function create_class(name)
  -- This is the metatable for instance of the class.
  local class_table = create_internal_class_table(name)
  local class_table_proxy = create_class_table_proxy(class_table)

  create_conversion_function(name, class_table, class_table_proxy)

  -- Lock down the class table.
  class_table.__metatable = class_table_proxy
  class_table.class = class_table_proxy

  return class_table, class_table_proxy
end

--- Callable object for defining classes with inheritance.
--
-- This object provides a method, `extends`, for defining classes with
-- inheritance. When called with the `extends` method, it creates a new class
-- table, sets up inheritance relationships, and returns a class definer object
-- for further class definition.
local class_callable = {
  --- Method to specify inheritance from one or more base classes.
  --
  -- This method creates a new class definition by invoking the 'create_class'
  -- function with an anonymous class name. It then creates a class definer
  -- using 'create_class_definer' and calls its 'extends' method with the
  -- provided arguments, representing the base classes. Finally, it returns the
  -- class definer for further class definition.
  --
  -- @param self The class callable object
  -- @param ... One or more base classes to inherit from
  -- @return A class definer object for defining Lua classes
  extends = function(self, ...)
    local class_table, class_table_proxy = create_class(anonymous_class_name)
    local definer = create_class_definer(class_table, class_table_proxy)
    definer:extends(...)
    return definer
  end;
}

--- Metatable for defining and instantiating classes.
--
-- This metatable is used for defining and instantiating classes. It defines a
-- `__call` metamethod, which is invoked when the metatable is called like a
-- function. Depending on the argument provided, it either defines a new class
-- or instantiates an existing class.
--
-- @param self The metatable object
-- @param name_or_definition The name of the class or a table containing the 
--                           class definition
-- @return A class definer object for defining a new class, or an instance of
--         the specified class
local class_metatable = {
  --- Method to define a Lua class by providing a name and definition.
  --
  -- This method resolves the class name and definition
  -- using 'class_argument_resolver', creates a class using 'create_class', and
  -- creates a class definer using 'create_class_definer'. If a class
  -- definition is provided, it directly returns the result of class definition
  -- using the definer, otherwise, it returns the definer for further class
  -- definition.
  --
  -- @param self The class metatable object
  -- @param name_or_definition The name of the class or the class definition
  -- @return A class definer object for defining Lua classes
  __call = function(self, name_or_definition)
    local name, class_definition = class_argument_resolver(name_or_definition)
    local class_table, class_table_proxy = create_class(name)
    local definer = create_class_definer(class_table, class_table_proxy)
    if class_definition then
      return definer(class_definition)
    else
      return definer
    end
  end;
}

--- Metatable for defining and instantiating classes.
--
-- This metatable is used for defining and instantiating classes. It defines a
-- `__call` metamethod, which is invoked when the metatable is called like a
-- function. Depending on the argument provided, it either defines a new class
-- or instantiates an existing class.
local class = setmetatable(class_callable, class_metatable)

_G.class = class

return {
  class=class,
}

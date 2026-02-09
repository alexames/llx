-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

-- The class module provides class-like behavior in Lua. It offers a
-- syntactically familiar way to define classes, create instances, and express
-- single and multiple inheritance.
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
-- The result is that `Line` is a callable class table containing all the
-- functions and members in the definition. Instances are created by calling the
-- class directly:
--
--     local f = Line(100)
--     print(f:get_length()) --> 100
--
-- Fields can also be added to the class after creation, and will be visible to
-- both existing and future instances:
--
--     Line.default_color = 'black'
--     print(f.default_color) --> black
--
-- # Initializer
--
-- `__init(self, ...)` is called automatically when an instance is created. It
-- receives the new instance as `self` followed by whatever arguments were
-- passed to the class call. Use it to set up instance state:
--
--     local Point = class 'Point' {
--       __init = function(self, x, y)
--         self.x = x
--         self.y = y
--       end,
--     }
--
-- `__init` is optional. If omitted, instances are created with an empty table.
--
-- # Custom Instantiation
--
-- `__new(...)` customizes the underlying table used for the instance. Unlike
-- `__init`, it does not receive `self` (since the instance does not yet exist).
-- It must return the table that will become the instance:
--
--     local Buffer = class 'Buffer' {
--       __new = function(size)
--         return { data = {}, capacity = size }
--       end,
--       __init = function(self, size)
--         self.size = 0
--       end,
--     }
--
-- When both `__new` and `__init` are defined, `__new` runs first to produce
-- the instance table, then `__init` is called on that table.
--
-- # Inheritance
--
-- Classes support single and multiple inheritance via `:extends(...)`:
--
--     local Rectangle = class 'Rectangle' : extends(Line) {
--       __init = function(self, length, width)
--         self.Line.__init(self, length)
--         self._width = width
--       end,
--
--       get_width = function(self)
--         return self._width
--       end,
--
--       get_area = function(self)
--         return self._width * self:get_length()
--       end,
--     }
--
-- When extending a named class, a reference to the superclass is added to the
-- derived class under the superclass's name (e.g. `self.Line`). This lets
-- derived classes call superclass methods explicitly, which is especially
-- useful for chaining `__init`.
--
-- Methods and fields are resolved by first checking the class itself, then
-- walking the superclass chain in declaration order. The first match wins.
--
-- Metamethods (keys starting with `__`) are inherited from superclasses and
-- propagated to subclasses. If a derived class defines its own metamethod, it
-- takes precedence over the inherited one.
--
-- # Properties
--
-- Properties are fields backed by getter and setter functions. They use the
-- decorator syntax with the `property` decorator:
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
--       },
--
--       ['area' | property] = {
--         get = function(self)
--            return self._width * self._length
--         end,
--       },
--     }
--
-- Properties look like plain fields to callers:
--
--     local r = Rectangle(10, 5)
--     print(r.width)  --> 5
--     r.width = 7
--     print(r.area)   --> 70
--
-- A property may define `get`, `set`, or both. Reading a property that has no
-- `get` or writing one that has no `set` raises an error.
--
-- Properties are inherited: a derived class has access to properties defined
-- on any of its superclasses.
--
-- # Anonymous classes
--
-- A class can be created without a name by passing a table directly:
--
--     local MyClass = class {
--       __init = function(self, value)
--         self.value = value
--       end,
--     }
--
-- Anonymous classes can also inherit from other classes:
--
--     local Derived = class : extends(Base) {
--       __init = function(self)
--         self.Base.__init(self)
--       end,
--     }
--
-- Anonymous classes have the internal name `<anonymous class>`.
--
-- # Conversion operators
--
-- Every class automatically receives a `to_class(value)` conversion function
-- that attempts to convert an arbitrary value into an instance of that class.
-- Named classes also get an alias `to_<ClassName>(value)`.
--
-- Conversion works by looking up a metamethod on the source value. For a named
-- class `Foo`, the lookup checks for `__to_Foo` first, then falls back to
-- checking for a metamethod keyed by the `Foo` class table itself. For
-- anonymous classes, only the class-table-keyed metamethod is checked.
--
--     local Celsius = class 'Celsius' {
--       __init = function(self, value) self.value = value end,
--     }
--
--     local Fahrenheit = class 'Fahrenheit' {
--       __init = function(self, value) self.value = value end,
--       __to_Celsius = function(self)
--         return Celsius((self.value - 32) * 5 / 9)
--       end,
--     }
--
--     local c = Celsius.to_class(Fahrenheit(212))
--     print(c.value) --> 100
--
-- If no matching conversion metamethod is found, `to_class` returns nil.
--
-- # Implementation details
--
-- ## Proxy class tables
--
-- Each class is represented by two tables:
--
-- 1. The *internal class table* (`class_table`) serves as the metatable for
--    instances. It holds all methods, metamethods, property definitions,
--    superclass references, and internal bookkeeping fields.
--
-- 2. The *class table proxy* (`class_table_proxy`) is the table returned to
--    user code — i.e. the value of `Line` in `local Line = class 'Line' {...}`.
--    It wraps the internal table with metamethods that:
--    - `__call`: create new instances (delegates to `__new` / `__init`)
--    - `__index`: reads resolve against the internal class table
--    - `__newindex`: writes go to the internal table and propagate metamethods
--    - `__pairs`: iterating the proxy iterates the internal table's members
--    - `__tostring`: returns the class name
--
-- `getmetatable(instance)` returns the proxy (because `class_table.__metatable`
-- is set to the proxy), keeping the internal class table hidden from external
-- code.
--
-- ## Superclass bookkeeping
--
-- Each class table maintains:
--
-- - `__superclasses`: an ordered array of direct base classes (internal tables)
-- - `__subclasses`: a map of subclass name to subclass proxy, for all classes
--   that directly extend this one
-- - `ClassName`: a direct reference to each named superclass, added to the
--   class table so that `self.Base` resolves during method calls
--
-- These fields support method resolution (walking `__superclasses` in order)
-- and metamethod propagation (pushing new metamethods down to `__subclasses`).
--
-- ## Metamethod inheritance
--
-- When a class defines a key starting with `__`, it is recorded in the
-- `__metafields` table. Metamethods are propagated to all subclasses that
-- have not defined their own version. When a superclass later defines a new
-- metamethod, it is pushed down to subclasses via `try_set_metafield_on_subclasses`.
--
-- ## Index resolution
--
-- The `__index` metamethod on the internal class table resolves field lookups
-- for instances. The lookup order is:
--
-- 1. `rawget(class_table, key)` — fields and methods on the class itself
-- 2. Walk `__superclasses` in order, returning the first match
--
-- `__defaultindex` stores a reference to this original `__index` function,
-- allowing classes to override `__index` in their definition while preserving
-- the default as a fallback.

--------------------------------------------------------------------------------
-- Utilities

local core = require 'llx.core'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

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

    __index = __index;
    __defaultindex = __index;

    __isinstance = __isinstance;

    __is_llx_class = true;
  }

  return class_table
end

--- Resolves the name and definition from a class creation argument.
--
-- This function determines whether the argument is a class name (string) or
-- an anonymous class definition (table). It returns the resolved name and
-- definition for use in class creation.
--
-- @param name_or_definition The name of the class (string) or a table
--                           containing the class definition for anonymous classes
-- @return name The resolved class name (or anonymous class name if a table was provided)
-- @return class_definition The class definition table (or nil if a name was provided)
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

-- Callable object for defining classes with inheritance.
--
-- This object provides a method, `extends`, for defining classes with
-- inheritance. When called with the `extends` method, it creates a new class
-- table, sets up inheritance relationships, and returns a class definer object
-- for further class definition.
local class_callable = {
  extends = function(self, ...)
    local class_table, class_table_proxy = create_class(anonymous_class_name)
    local definer = create_class_definer(class_table, class_table_proxy)
    definer:extends(...)
    return definer
  end;
}

-- Metatable for defining and instantiating classes.
--
-- This metatable is used for defining and instantiating classes. It defines a
-- `__call` metamethod, which is invoked when the metatable is called like a
-- function. Depending on the argument provided, it either defines a new class
-- or instantiates an existing class.
local class_metatable = {
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
class = setmetatable(class_callable, class_metatable)

return _M

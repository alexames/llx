-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

-- A class is a designed to mimic class-like behavior from other languages in
-- Lua. It provides a syntacticaly similar method of initializing the class
-- definition, and allows for basic inheritance.
--
-- A class can be created as follows:
--
--     local Line = class 'Line' {
--       __init = function(self, length)
--         self.length = length
--       end;
--
--       get_length = function(self)
--         return self.length
--       end
--     }
--
-- The result is that the table Line now contains the class definition. Instances
-- of the class can be instantiated like so:
--
--     f = Line(100)
--
-- (This is because the class definition has itself a `__call` metamethod)
--
-- Classes also support inheritance:
--
--     local Rectangle = class 'Rectangle' : extends(Line) {
--       __init = function(self, length, width)
--         self.Line.__init(self, length)
--         self.width = width
--       end;
--
--       get_width = function(self)
--         return self.width
--       end
--     }
--
-- This Rectangle class inherits the values and functions from the Line
-- superclass. Additionally, when inheriting from a class, a reference to that
-- class is added to the class definition automatically. (Is this needed 
-- though?)
--
-- mention properties
-- mention __metamethods
--
-- Implementation details:
--

--------------------------------------------------------------------------------
-- Utilities

local core = require 'llx/src/core'
local getmetafield = core.getmetafield

local function try_set_metafield(class_table, key, value)
  if class_table.__metafields[key] == nil then
    rawset(class_table, key, value)
  end
end

local function try_set_metafield_on_subclasses(class_table, key, value)
  for _, subclass in pairs(class_table.__subclasses) do
    try_set_metafield(subclass, key, value)
  end
end

local function handle_potential_metafield(class_table, key, value)
  -- Assign metafield value to class_table[key] if and only if
  -- class_table.__metafields does not define it.
  if type(key) == 'string' and key:sub(1, 2) == '__' then
    class_table.__metafields[key] = value
    try_set_metafield_on_subclasses(class_table, key, value)
  end
end

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

local function create_class_definer(class_table, class_table_proxy)
  -- By returning this class definer object, we can do these things:
  --   class 'foo' { ... }
  -- or 
  --   class 'foo' : extends(bar) { ... }
  local class_definer = nil
  class_definer = setmetatable({
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
  }, {
    __call = function(self, class_definition)
      local properties = class_table.__properties
      for k, v in pairs(class_definition) do
        if k.__isproperty then
          rawset(properties, k.__key, v)
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
  })
  return class_definer
end

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

local function create_internal_class_table(name)
  local class_table = nil

  local function try_get_property(class_table, t, k)
    -- Is this a property?
    local properties = class_table.__properties
    local property = properties and properties[k]
    if property then
      assert(type(property) == 'table')
      local getter = property.get
      if not getter then
        -- error
      else
        local v = getter(t)
        return v
      end
    end

    if class_table.__superclasses then
      for _, base in ipairs(class_table.__superclasses) do
        local value = try_get_property(base, t, k)
        if value then
          return value
        end
      end
    end
  end

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

  -- If the object doesn't have a field, check the metatable,
  -- then any base classes
  local function __index(t, k)
    return try_get_property(class_table, t, k)
        or rawget(class_table, k)
        or try_get_superclass_value(k)
  end

  local function try_set_property(class_table, t, k, v)
    local properties = class_table.__properties
    local property = properties and properties[k]
    if property then
      assert(type(property) == 'table')
      local setter = property.set
      if not setter then
        -- error
        return
      end
      setter(t, v)
      return true
    end
    if class_table.__superclasses then
      for _, base in ipairs(class_table.__superclasses) do
        if try_set_property(base, t, k, v) then
          return true
        end
      end
    end
    return false
  end

  local function __newindex(t, k, v)
    if try_set_property(class_table, t, k, v) then return
    else rawset(t, k, v)
    end
  end

  local function __isinstance(self, o)
    return isinstance_impl(getmetatable(o), class_table)
  end

  class_table = {
    __name = name;

    __properties = {};
    __superclasses = {};
    __subclasses = {};
    __metafields = {};

    __internalindex = __internalindex;
    __index = __index;
    __defaultindex = __index;
    __newindex = __newindex;

    __isinstance = __isinstance;
  }

  return class_table
end

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

local function initialize_conversion_function(
    name, class_table, class_table_proxy)
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

local function create_class(name)
  -- This is the metatable for instance of the class.
  local class_table = create_internal_class_table(name)
  local class_table_proxy = create_class_table_proxy(class_table)

  initialize_conversion_function(name, class_table, class_table_proxy)

  -- Lock down the class table.
  class_table.__metatable = class_table_proxy
  class_table.class = class_table_proxy

  return class_table, class_table_proxy
end

--- Placeholder LDoc documentation
-- Some description, can be over several lines.
-- @param p A parameter
-- @return A value
class = setmetatable({
  extends = function(self, ...)
    local class_table, class_table_proxy = create_class(anonymous_class_name)
    local definer = create_class_definer(class_table, class_table_proxy)
    definer:extends(...)
    return definer
  end;
}, {
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
})

function property(name)
  return {__key=name, __isproperty=true}
end

return class

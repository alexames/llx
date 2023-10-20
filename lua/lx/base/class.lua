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

local function startswith(str, start)
   return str:sub(1, #start) == start
end

local function try_set_metafield(class_table, key, value)
  if class_table.__metafields[key] == nil then
    class_table[key] = value
  end
end

local function set_metafield_on_subclasses(class_table, key, value)
  for _, subclass in pairs(class_table.__subclasses) do
    try_set_metafield(subclass, key, value)
  end
end

local function set_metafield(class_table, key, value)
  -- Assign metafield value to class_table[key] if and only if
  -- class_table.__metafields does not define it.
  if type(key) == 'string' and startswith(key, '__') then
    class_table.__metafields[key] = value
    set_metafield_on_subclasses(class_table, key, value)
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

local function create_class_definer(class_table, class_table_proxy)
  -- By returning this class definer object, we can do these things:
  --   class 'foo' { ... }
  -- or 
  --   class 'foo' : extends(bar) { ... }
  local class_definer = nil
  class_definer = setmetatable({
    extends = function(self, ...)
      local arg = {...}
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

      -- TODO: property fixup

      return class_definer
    end
  }, {
    __call = function(self, class_definition)
      for k, v in pairs(class_definition) do
        rawset(class_table, k, v)
        set_metafield(class_table, k, v)
      end

      -- I think this needs to be set up to be recursive.
      -- I'm also concerned about the ordering of the superclasses and
      -- whether this will respect that.
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
      set_metafield(class_table, k, v)
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

    __tostring = function()
      return class_table.__name
    end;
  }
  return setmetatable(class_table_proxy, class_table_proxy_metatable)
end

local function create_internal_class_table(name)
  local class_table = nil
  -- If the object doesn't have a field, check the metatable,
  -- then any base classes
  local function __index(t, k)
    -- Does the class metatable have the field?
    local value = rawget(class_table, k)
    if value then return value end

    -- Do any of the base classes have the field?
    if class_table.__superclasses then
      for _, base in ipairs(class_table.__superclasses) do
        local value = base[k]
        if value then return value end
      end
    end
  end

  local function isinstance(o)
    return isinstance_impl(getmetatable(o), class_table)
  end

  class_table = {
    __name = name;

    __superclasses = {};
    __subclasses = {};
    __metafields = {};

    __index = __index;
    __defaultindex = __index;

    isinstance = isinstance;
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
    name = '<anonymous class>'
    class_definition = name_or_definition
  end
  return name, class_definition
end

local function create_class(name)
  -- This is the metatable for instance of the class.
  local class_table = create_internal_class_table(name)
  local class_table_proxy = create_class_table_proxy(class_table)

  -- Lock down the class table.
  class_table.__metatable = class_table_proxy;

  return class_table, class_table_proxy
end

class = setmetatable({
  extends = function(self, ...)
    local class_table, class_table_proxy = create_class('<anonymous class>')
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

return class

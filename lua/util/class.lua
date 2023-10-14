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

local function endswith(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local function class(name)
  -- This is the metatable for instance of the class.
  local class_table = nil
  class_table = {
    __name = name;
    __superclasses = {};
    __subclasses = {};
    __metafields = {};

    -- If the object doesn't have a field, check the metatable,
    -- then any base classes
    __index = function(t, k)
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
  }

  function try_set_metafield(class_table, key, value)
    if class_table.__metafields[key] == nil then
      class_table[key] = value
    end
  end

  function set_metafield_on_subclasses(class_table, key, value)
    for _, subclass in pairs(class_table.__subclasses) do
      try_set_metafield(subclass, key, value)
    end
  end

  function set_metafield(class_table, key, value)
    -- Assign metafield value to class_table[key] if and only if
    -- class_table.__metafields does not define it.
    if type(key) == 'string' and startswith(key, '__') then
      class_table.__metafields[key] = value
      set_metafield_on_subclasses(class_table, key, value)
    end
  end

  local dummy_class_table = {}
  setmetatable(dummy_class_table, {
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
      return next, class_table, nil
    end;

    __len = function()
      return #class_table
    end;

    __eq = function(lhs, rhs)
      local other = (rawequal(dummy_class_table, lhs) and rhs or lhs)
      return rawequal(class_table, other)
    end;
  })

  class_table.__defaultindex = class_table.__index

  -- By returning this class definer object, we can do these things:
  --   class 'foo' { ... }
  -- or 
  --   class 'foo' : extends(bar) { ... }
  local class_definer = nil
  class_definer = setmetatable(
    {
      extends = function(self, ...)
        local arg = {...}
        for i, base in ipairs(arg) do
          local base_name = base.__name
          if base_name then
            class_table[base_name] = base
          end

          -- Bi-directional extends/extendedby bookkeeping.
          class_table.__superclasses[i] = base
          local extendedby = base.__subclasses
          if extendedby then
            extendedby[class_table.__name] = class_table
          end
        end

        -- TODO: property fixup

        return class_definer
      end
    },
    {
      __call = function(self, definition_table)
        for k, v in pairs(definition_table) do
          rawset(class_table, k, v)
          set_metafield(class_table, k, v)
        end

        -- I think this needs to be set up to be recursive.
        -- I'm also concerned about the ordering of the superclasses and
        -- whether this will respect that.
        for _, superclass in ipairs(class_table.__superclasses) do
          for k, v in pairs(superclass.__metafields) do
            try_set_metafield(class_table, k, v)
          end
        end
        return dummy_class_table
      end
    })
  return class_definer
end

local function test()
  require 'util/unit'

  local Base = class "Base" {
    __init = function(self, a, b, c)
      self.a = a
      self.b = b
      self.c = c
    end;

    getStuff = function(self)
      return {self.a, self.b, self.c}
    end;

    __tostring = function(self)
      return string.format('Base(%s, %s, %s)', self.a, self.b, self.c)
    end;

    __metamethod = function(self)
      return 999
    end;

    staticValue = 100;
  }

  local Derived = class "Derived" : extends(Base) {
    __init = function(self, a, b, c, d, e)
      self.Base.__init(self, a, b, c)
      self.d = d
      self.e = e
      self.f = "f"
    end;

    getStuff = function(self)
      local result = self.Base.getStuff(self)
      table.insert(result, self.d)
      table.insert(result, self.e)
      table.insert(result, self.f)
      return result
    end;

    __tostring = function(self)
      return string.format(
        'Derived(%s, %s, %s, %s, %s, %s)',
        tostring(self.a), tostring(self.b), tostring(self.c),
        tostring(self.d), tostring(self.e), tostring(self.f))
    end;


    staticValue = 200;
  }

  local AnotherDerived = class "AnotherDerived" : extends(Base) {}

  function AnotherDerived:__init(a, b, c, d, e)
    self.Base.__init(self, a, b, c)
    self.d = d
    self.e = e
    self.f = "f"
  end

  function AnotherDerived:getStuff()
    local result = self.Base.getStuff(self)
    table.insert(result, self.d)
    table.insert(result, self.e)
    table.insert(result, self.f)
    return result
  end;

  EXPECT_NE(Base.getStuff, nil)
  EXPECT_NE(Base(1, 2, 3), nil)
  local base = Base(1, 2, 3)
  EXPECT_EQ(Base, getmetatable(base))
  EXPECT_EQ(getmetatable(base), Base)
  EXPECT_EQ(tostring(base), 'Base(1, 2, 3)')
  EXPECT_EQ(base.getStuff, Base.getStuff)
  EXPECT_THAT(base:getStuff(), Listwise(Equals, {1, 2, 3}))
  EXPECT_EQ(getmetatable(base).__metamethod(), 999)

  base1 = Base(1, 2, 3)
  EXPECT_THAT(base1:getStuff(), Listwise(Equals, {1, 2, 3}))

  base2 = Base(6, 7, 8)
  EXPECT_THAT(base1:getStuff(), Listwise(Equals, {1, 2, 3}))
  EXPECT_THAT(base2:getStuff(), Listwise(Equals, {6, 7, 8}))

  derived = Derived(10, 20, 30, 40, 50)
  EXPECT_EQ(tostring(derived), 'Derived(10, 20, 30, 40, 50, f)')
  EXPECT_THAT(derived:getStuff(),
              Listwise(Equals, {10, 20, 30, 40, 50, 'f'}))
  -- EXPECT_EQ(getmetatable(derived).__metamethod(), 999)

  anotherDerived = AnotherDerived(100, 200, 300, 400, 500)
  EXPECT_THAT(anotherDerived:getStuff(),
              Listwise(Equals, {100, 200, 300, 400, 500, 'f'}))
end

return {class, test}

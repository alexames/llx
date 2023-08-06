require 'printValue'

function class(name)
  local classTable = {}
  local classTableMetatable = {}
  classTable.__name = name
  classTable.__extends = {};

  -- Used to initialize an instance of the class.
  function classTableMetatable:__call(...)
    local object = setmetatable({}, classTable)
    if classTable.__init then
      classTable.__init(object, unpack(arg))
    end
    return object
  end

  -- If the object doesn't have a field, check the metatable, then any base classes
  function classTable:__defaultindex(key)
    -- Does the class metatable have the field?
    local value = rawget(classTable, key)
    if value then return value end

    -- Do any of the base classes have the field?
    if classTable.__extends then
      for unused, base in ipairs(classTable.__extends) do
        local value = rawget(base, key)
        if value then return value end
      end
    end
  end
  classTable.__index = classTable.__defaultindex

  setmetatable(classTable, classTableMetatable)
  _G[name] = classTable

  -- By returning this class definer object, we can do these things:
  --   class 'foo' { ... }
  -- or 
  --   class 'foo' : extends(bar) { ... }
  local classDefiner = {}
  function classDefiner:extends(...)
    for i=1, arg.n do
      local base = arg[i]
      classTable.__extends[i] = base
      if base.__name then
        classTable[base.__name] = base
      end
    end
    return classDefiner
  end

  local classDefinerMetatable = {}
  function classDefinerMetatable:__call(metatable)
    for k, v in pairs(metatable) do
      classTable[k] = v
    end
  end

  return setmetatable(classDefiner, classDefinerMetatable)
end

function test()
  require 'unit'

  class "Base" {
    __init = function(self, a, b, c)
      self.a = a
      self.b = b
      self.c = c
    end;

    getStuff = function(self)
      return {self.a, self.b, self.c}
    end;

    staticValue = 100;
  }

  class "Derived" : extends(Base) {
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

    staticValue = 200;
  }

  class "AnotherDerived" : extends(Base)

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

  base1 = Base(1, 2, 3)
  EXPECT_EQ(base1:getStuff(), {1, 2, 3})

  base2 = Base(6, 7, 8)
  EXPECT_EQ(base1:getStuff(), {1, 2, 3})
  EXPECT_EQ(base2:getStuff(), {6, 7, 8})

  derived = Derived(10, 20, 30, 40, 50)
  EXPECT_EQ(derived:getStuff(), {10, 20, 30, 40, 50, 'f'})

  anotherDerived = AnotherDerived(100, 200, 300, 400, 500)
  EXPECT_EQ(anotherDerived:getStuff(), {100, 200, 300, 400, 500, 'f'})
end


local unit = require 'llx.unit'
local llx = require 'llx'

local getclass = require 'llx.getclass' . getclass
local class = require 'llx.class' . class
local types = require 'llx.types'

_ENV = unit.create_test_env(_ENV)

describe('getclass', function()
  describe('with nil values', function()
    it('should return types.Nil for nil', function()
      expect(getclass(nil)).to.be_equal_to(types.Nil)
    end)
  end)

  describe('with boolean values', function()
    it('should return types.Boolean for true', function()
      expect(getclass(true)).to.be_equal_to(types.Boolean)
    end)

    it('should return types.Boolean for false', function()
      expect(getclass(false)).to.be_equal_to(types.Boolean)
    end)
  end)

  describe('with number values', function()
    it('should return types.Number for an integer', function()
      expect(getclass(42)).to.be_equal_to(types.Number)
    end)

    it('should return types.Number for a float', function()
      expect(getclass(3.14)).to.be_equal_to(types.Number)
    end)

    it('should return types.Number for zero', function()
      expect(getclass(0)).to.be_equal_to(types.Number)
    end)

    it('should return types.Number for a negative number', function()
      expect(getclass(-100)).to.be_equal_to(types.Number)
    end)

    it('should return types.Number for math.huge', function()
      expect(getclass(math.huge)).to.be_equal_to(types.Number)
    end)
  end)

  describe('with string values', function()
    it('should return types.String for a string', function()
      expect(getclass('hello')).to.be_equal_to(types.String)
    end)

    it('should return types.String for an empty string', function()
      expect(getclass('')).to.be_equal_to(types.String)
    end)

    it('should return types.String for a numeric string', function()
      expect(getclass('42')).to.be_equal_to(types.String)
    end)
  end)

  describe('with plain table values', function()
    it('should return types.Table for an empty table '
      .. 'without metatable', function()
      expect(getclass({})).to.be_equal_to(types.Table)
    end)

    it('should return types.Table for a non-empty table '
      .. 'without metatable', function()
      expect(getclass({1, 2, 3})).to.be_equal_to(types.Table)
    end)

    it('should return types.Table for a table with string '
      .. 'keys and no metatable', function()
      expect(getclass({a = 1, b = 2})).to.be_equal_to(types.Table)
    end)
  end)

  describe('with tables that have metatables', function()
    it('should return the metatable for a table with a metatable', function()
      local mt = {}
      local t = setmetatable({}, mt)
      expect(getclass(t)).to.be_equal_to(mt)
    end)

    it('should return the metatable even if it is not a class', function()
      local mt = { __tostring = function() return 'custom' end }
      local t = setmetatable({}, mt)
      expect(getclass(t)).to.be_equal_to(mt)
    end)
  end)

  describe('with function values', function()
    it('should return types.Function for a regular function', function()
      expect(getclass(function() end)).to.be_equal_to(types.Function)
    end)

    it('should return types.Function for print', function()
      expect(getclass(print)).to.be_equal_to(types.Function)
    end)
  end)

  describe('with thread (coroutine) values', function()
    it('should return types.Thread for a coroutine', function()
      local co = coroutine.create(function() end)
      expect(getclass(co)).to.be_equal_to(types.Thread)
    end)
  end)

  describe('with class instances', function()
    it('should return the class metatable for a class instance', function()
      local Foo = class 'Foo' {}
      local f = Foo()
      -- getclass returns the raw metatable, which for a class instance
      -- is the class proxy (since __metatable is set to the proxy)
      local mt = getmetatable(f)
      expect(getclass(f)).to.be_equal_to(mt)
    end)

    it('should return different metatables for instances '
      .. 'of different classes', function()
      local Foo = class 'Foo' {}
      local Bar = class 'Bar' {}
      local f = Foo()
      local b = Bar()
      expect(getclass(f)).to_not.be_equal_to(getclass(b))
    end)

    it('should return the derived class metatable '
      .. 'for a derived instance', function()
      local Base = class 'Base' {}
      local Derived = class 'Derived' : extends(Base) {}
      local d = Derived()
      expect(getclass(d)).to.be_equal_to(getmetatable(d))
    end)

    it('should return different metatables for base '
      .. 'and derived instances', function()
      local Base = class 'Base' {}
      local Derived = class 'Derived' : extends(Base) {}
      local b = Base()
      local d = Derived()
      expect(getclass(b)).to_not.be_equal_to(getclass(d))
    end)
  end)

  describe('consistency with types module', function()
    it('should return a type table with __name for nil', function()
      local cls = getclass(nil)
      expect(cls.__name).to.be_equal_to('nil')
    end)

    it('should return a type table with __name for boolean', function()
      local cls = getclass(true)
      expect(cls.__name).to.be_equal_to('Boolean')
    end)

    it('should return a type table with __name for number', function()
      local cls = getclass(42)
      expect(cls.__name).to.be_equal_to('Number')
    end)

    it('should return a type table with __name for string', function()
      local cls = getclass('hello')
      expect(cls.__name).to.be_equal_to('String')
    end)

    it('should return a type table with __name for table', function()
      local cls = getclass({})
      expect(cls.__name).to.be_equal_to('Table')
    end)

    it('should return a type table with __name for function', function()
      local cls = getclass(function() end)
      expect(cls.__name).to.be_equal_to('function')
    end)

    it('should return a type table with __name for thread', function()
      local co = coroutine.create(function() end)
      local cls = getclass(co)
      expect(cls.__name).to.be_equal_to('Thread')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

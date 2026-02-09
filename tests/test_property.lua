local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local property_module = require 'llx.property'
local unit = require 'llx.unit'
local llx = require 'llx'

local class = class_module.class
local Decorator = decorator.Decorator
local Property = property_module.Property
local property = property_module.property

_ENV = unit.create_test_env(_ENV)

describe('Property', function()
  describe('Property class', function()
    it('should exist as a class', function()
      expect(Property).to_not.be_nil()
    end)

    it('should be a subclass of Decorator', function()
      local p = Property()
      expect(p).to_not.be_nil()
    end)

    it('should have a decorate method', function()
      local p = Property()
      expect(p.decorate).to.be_a('function')
    end)
  end)

  describe('property instance', function()
    it('should exist as an instance of Property', function()
      expect(property).to_not.be_nil()
    end)

    it('should work with __bor operator', function()
      local result = 'my_prop' | property
      expect(result.__isdecorator).to.be_true()
      expect(result.name).to.be_equal_to('my_prop')
    end)
  end)

  describe('getter-only property', function()
    it('should return value from getter', function()
      local Foo = class 'Foo' {
        __init = function(self, val)
          self._value = val
        end,
        ['value' | property] = {
          get = function(self)
            return self._value
          end,
        },
      }
      local f = Foo(42)
      expect(f.value).to.be_equal_to(42)
    end)

    it('should throw error when trying to set a getter-only property', function()
      local Foo = class 'Foo' {
        ['value' | property] = {
          get = function(self)
            return self._value
          end,
        },
      }
      local f = Foo()
      expect(function() f.value = 100 end).to.throw()
    end)

    it('should return nil when backing field is not set', function()
      local Foo = class 'Foo' {
        ['value' | property] = {
          get = function(self)
            return self._value
          end,
        },
      }
      local f = Foo()
      expect(f.value).to.be_nil()
    end)
  end)

  describe('setter-only property', function()
    it('should set value via setter', function()
      local Foo = class 'Foo' {
        ['value' | property] = {
          set = function(self, v)
            self._value = v
          end,
        },
      }
      local f = Foo()
      f.value = 99
      expect(f._value).to.be_equal_to(99)
    end)

    it('should throw error when trying to get a setter-only property', function()
      local Foo = class 'Foo' {
        ['value' | property] = {
          set = function(self, v)
            self._value = v
          end,
        },
      }
      local f = Foo()
      f.value = 99
      expect(function() local x = f.value end).to.throw()
    end)
  end)

  describe('getter and setter property', function()
    it('should set and get value', function()
      local Foo = class 'Foo' {
        ['value' | property] = {
          get = function(self)
            return self._value
          end,
          set = function(self, v)
            self._value = v
          end,
        },
      }
      local f = Foo()
      f.value = 123
      expect(f.value).to.be_equal_to(123)
    end)

    it('should allow updating value multiple times', function()
      local Foo = class 'Foo' {
        ['value' | property] = {
          get = function(self)
            return self._value
          end,
          set = function(self, v)
            self._value = v
          end,
        },
      }
      local f = Foo()
      f.value = 10
      expect(f.value).to.be_equal_to(10)
      f.value = 20
      expect(f.value).to.be_equal_to(20)
      f.value = 30
      expect(f.value).to.be_equal_to(30)
    end)

    it('should have custom logic in getter', function()
      local Foo = class 'Foo' {
        ['doubled' | property] = {
          get = function(self)
            return self._raw * 2
          end,
          set = function(self, v)
            self._raw = v
          end,
        },
      }
      local f = Foo()
      f.doubled = 5
      expect(f.doubled).to.be_equal_to(10)
    end)

    it('should have custom logic in setter', function()
      local Foo = class 'Foo' {
        ['clamped' | property] = {
          get = function(self)
            return self._clamped
          end,
          set = function(self, v)
            if v < 0 then v = 0 end
            if v > 100 then v = 100 end
            self._clamped = v
          end,
        },
      }
      local f = Foo()
      f.clamped = 150
      expect(f.clamped).to.be_equal_to(100)
      f.clamped = -50
      expect(f.clamped).to.be_equal_to(0)
      f.clamped = 42
      expect(f.clamped).to.be_equal_to(42)
    end)
  end)

  describe('multiple properties on one class', function()
    it('should support multiple properties', function()
      local Foo = class 'Foo' {
        ['x' | property] = {
          get = function(self) return self._x end,
          set = function(self, v) self._x = v end,
        },
        ['y' | property] = {
          get = function(self) return self._y end,
          set = function(self, v) self._y = v end,
        },
      }
      local f = Foo()
      f.x = 10
      f.y = 20
      expect(f.x).to.be_equal_to(10)
      expect(f.y).to.be_equal_to(20)
    end)

    it('should keep properties independent', function()
      local Foo = class 'Foo' {
        ['a' | property] = {
          get = function(self) return self._a end,
          set = function(self, v) self._a = v end,
        },
        ['b' | property] = {
          get = function(self) return self._b end,
          set = function(self, v) self._b = v end,
        },
      }
      local f = Foo()
      f.a = 100
      f.b = 200
      expect(f.a).to_not.be_equal_to(f.b)
    end)
  end)

  describe('properties with inheritance', function()
    it('should inherit property from base class', function()
      local Base = class 'Base' {
        ['value' | property] = {
          get = function(self) return self._value end,
          set = function(self, v) self._value = v end,
        },
      }
      local Derived = class 'Derived' : extends(Base) {}
      local d = Derived()
      d.value = 42
      expect(d.value).to.be_equal_to(42)
    end)

    it('should allow derived class to have its own properties', function()
      local Base = class 'Base' {
        ['base_prop' | property] = {
          get = function(self) return self._base end,
          set = function(self, v) self._base = v end,
        },
      }
      local Derived = class 'Derived' : extends(Base) {
        ['derived_prop' | property] = {
          get = function(self) return self._derived end,
          set = function(self, v) self._derived = v end,
        },
      }
      local d = Derived()
      d.base_prop = 10
      d.derived_prop = 20
      expect(d.base_prop).to.be_equal_to(10)
      expect(d.derived_prop).to.be_equal_to(20)
    end)
  end)

  describe('non-property fields', function()
    it('should still allow regular field access on instances with properties', function()
      local Foo = class 'Foo' {
        ['prop' | property] = {
          get = function(self) return self._prop end,
          set = function(self, v) self._prop = v end,
        },
        regular_field = 42,
      }
      local f = Foo()
      expect(f.regular_field).to.be_equal_to(42)
    end)

    it('should still allow regular field assignment on instances with properties', function()
      local Foo = class 'Foo' {
        ['prop' | property] = {
          get = function(self) return self._prop end,
          set = function(self, v) self._prop = v end,
        },
      }
      local f = Foo()
      f.normal = 'hello'
      expect(f.normal).to.be_equal_to('hello')
    end)
  end)

  describe('property instances are independent', function()
    it('should have independent state per instance', function()
      local Foo = class 'Foo' {
        ['value' | property] = {
          get = function(self) return self._value end,
          set = function(self, v) self._value = v end,
        },
      }
      local f1 = Foo()
      local f2 = Foo()
      f1.value = 100
      f2.value = 200
      expect(f1.value).to.be_equal_to(100)
      expect(f2.value).to.be_equal_to(200)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

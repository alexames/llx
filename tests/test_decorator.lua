local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local unit = require 'llx.unit'
local llx = require 'llx'

local class = class_module.class
local Decorator = decorator.Decorator

_ENV = unit.create_test_env(_ENV)

describe('Decorator', function()
  describe('base class', function()
    it('should be creatable as a class', function()
      expect(Decorator).to_not.be_nil()
    end)

    it('should be instantiable', function()
      local d = Decorator()
      expect(d).to_not.be_nil()
    end)

    it('should have a decorate method', function()
      local d = Decorator()
      expect(d.decorate).to.be_a('function')
    end)

    it('should return identity from decorate method', function()
      local d = Decorator()
      local target = {}
      local name = 'test_name'
      local value = function() end
      local r_target, r_name, r_value = d:decorate(target, name, value)
      expect(r_target).to.be_equal_to(target)
      expect(r_name).to.be_equal_to(name)
      expect(r_value).to.be_equal_to(value)
    end)

    it('should return the same class, name, and value unchanged', function()
      local d = Decorator()
      local my_class = class 'my_test_class' {}
      local name = 'my_func'
      local value = 42
      local r_class, r_name, r_value = d:decorate(my_class, name, value)
      expect(r_class).to.be_equal_to(my_class)
      expect(r_name).to.be_equal_to('my_func')
      expect(r_value).to.be_equal_to(42)
    end)
  end)

  describe('__bor operator', function()
    it('should create a decorator table when used with a string', function()
      local d = Decorator()
      local result = 'func_name' | d
      expect(result).to_not.be_nil()
      expect(type(result)).to.be_equal_to('table')
    end)

    it('should set __isdecorator flag on result', function()
      local d = Decorator()
      local result = 'func_name' | d
      expect(result.__isdecorator).to.be_true()
    end)

    it('should store the name from lhs', function()
      local d = Decorator()
      local result = 'my_function' | d
      expect(result.name).to.be_equal_to('my_function')
    end)

    it('should store the decorator in decorator_table', function()
      local d = Decorator()
      local result = 'func_name' | d
      expect(#result.decorator_table).to.be_equal_to(1)
      expect(result.decorator_table[1]).to.be_equal_to(d)
    end)
  end)

  describe('chaining decorators', function()
    it('should allow chaining two decorators', function()
      local d1 = Decorator()
      local d2 = Decorator()
      local result = 'func_name' | d1 | d2
      expect(result.__isdecorator).to.be_true()
      expect(result.name).to.be_equal_to('func_name')
      expect(#result.decorator_table).to.be_equal_to(2)
    end)

    it('should preserve decorator order when chaining', function()
      local d1 = Decorator()
      local d2 = Decorator()
      local result = 'func_name' | d1 | d2
      expect(result.decorator_table[1]).to.be_equal_to(d1)
      expect(result.decorator_table[2]).to.be_equal_to(d2)
    end)

    it('should allow chaining three decorators', function()
      local d1 = Decorator()
      local d2 = Decorator()
      local d3 = Decorator()
      local result = 'func_name' | d1 | d2 | d3
      expect(result.__isdecorator).to.be_true()
      expect(#result.decorator_table).to.be_equal_to(3)
      expect(result.decorator_table[1]).to.be_equal_to(d1)
      expect(result.decorator_table[2]).to.be_equal_to(d2)
      expect(result.decorator_table[3]).to.be_equal_to(d3)
    end)

    it('should keep the same name when chaining', function()
      local d1 = Decorator()
      local d2 = Decorator()
      local d3 = Decorator()
      local result = 'original_name' | d1 | d2 | d3
      expect(result.name).to.be_equal_to('original_name')
    end)
  end)

  describe('custom decorator subclass', function()
    it('should allow creating a subclass of Decorator', function()
      local MyDecorator = class 'MyDecorator' : extends(Decorator) {
        decorate = function(self, target, name, value)
          return target, 'modified_' .. name, value
        end,
      }
      local d = MyDecorator()
      local target = {}
      local r_target, r_name, r_value = d:decorate(target, 'func', 123)
      expect(r_name).to.be_equal_to('modified_func')
      expect(r_value).to.be_equal_to(123)
    end)

    it('should work with __bor when subclassed', function()
      local MyDecorator = class 'MyDecorator' : extends(Decorator) {
        decorate = function(self, target, name, value)
          return target, name, value
        end,
      }
      local d = MyDecorator()
      local result = 'some_name' | d
      expect(result.__isdecorator).to.be_true()
      expect(result.name).to.be_equal_to('some_name')
      expect(result.decorator_table[1]).to.be_equal_to(d)
    end)

    it('should allow chaining custom decorators with '
      .. 'base decorators', function()
      local MyDecorator = class 'MyDecorator' : extends(Decorator) {
        decorate = function(self, target, name, value)
          return target, name, value
        end,
      }
      local d1 = Decorator()
      local d2 = MyDecorator()
      local result = 'func' | d1 | d2
      expect(#result.decorator_table).to.be_equal_to(2)
      expect(result.decorator_table[1]).to.be_equal_to(d1)
      expect(result.decorator_table[2]).to.be_equal_to(d2)
    end)
  end)

  describe('integration with class', function()
    it('should apply decorator when defining a class', function()
      local applied = false
      local TestDecorator = class 'TestDecorator' : extends(Decorator) {
        decorate = function(self, target, name, value)
          applied = true
          return target, name, value
        end,
      }
      local td = TestDecorator()
      local MyClass = class 'MyClass' {
        ['my_method' | td] = function(self) return 42 end,
      }
      expect(applied).to.be_true()
    end)

    it('should allow decorator to modify where value is stored', function()
      local custom_table = {}
      local RedirectDecorator = class 'RedirectDecorator' : extends(Decorator) {
        decorate = function(self, target, name, value)
          return custom_table, name, value
        end,
      }
      local rd = RedirectDecorator()
      local MyClass = class 'MyClass' {
        ['my_method' | rd] = function() return 99 end,
      }
      expect(custom_table.my_method).to_not.be_nil()
      expect(custom_table.my_method()).to.be_equal_to(99)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local property = require 'llx.property'
local proxy = require 'llx.proxy'
local unit = require 'llx.unit'
local llx = require 'llx'

local class = class_module.class
local Proxy = proxy.Proxy
local set_proxy_value = proxy.set_proxy_value

function ProxySetter(proxy)
  return function(v)
    set_proxy_value(proxy, v)
    return true
  end
end

local test_index = 0
local Test = class 'Test' : extends(decorator.Decorator) {
  decorate = function(self, class_table, name, value)
    test_index = test_index + 1
    local key = {index=test_index, name={name}, parameter={}, __istest=true}
    return class_table, key, value
  end,
}
local test = Test()

_ENV = unit.create_test_env(_ENV)

describe('class', function()
  it('should have class fields accessible on class', function()
    local foo = class 'foo' {
      field = 100
    }
    expect(foo.field).to.be_equal_to(100)
  end)

  it('should have member fields accessible on instance', function()
    local foo = class 'foo' {
      field = 100
    }
    local f = foo()
    expect(f.field).to.be_equal_to(100)
  end)

  it('should call class functions correctly', function()
    local mock = Mock()
    mock:mockReturnValue(100)
    local foo = class 'foo' {
      func = mock
    }
    expect(foo.func()).to.be_equal_to(100)
    expect(mock).to.have_been_called_times(1)
  end)

  it('should call member functions with self correctly', function()
    local mock = Mock()
    mock:mockReturnValue(100)
    local foo = class 'foo' {
      func = mock
    }
    local f = foo()
    expect(f:func()).to.be_equal_to(100)
    expect(mock).to.have_been_called_times(1)
    local call = mock:get_last_call()
    expect(call.args[1]).to.be_equal_to(f)
  end)

  it('should set self reference correctly in member functions', function()
    local mock = Mock()
    local self_ref = Proxy()
    mock:mockImplementation(function(self)
      set_proxy_value(self_ref, self)
      return 100
    end)
    local foo = class 'foo' {
      func = mock
    }
    local f = foo()
    f:func()
    expect(f).to.be_equal_to(self_ref)
    expect(mock).to.have_been_called_times(1)
  end)

  it('should set metatable to class for instances', function()
    local foo = class 'foo' {}
    local f = foo()
    expect(getmetatable(f)).to.be_equal_to(foo)
  end)

  it('should allow setting instance fields', function()
    local foo = class 'foo' {}
    local f = foo()
    f.bar = 100
    expect(f.bar).to.be_equal_to(100)
  end)

  it('should set class field and make it accessible on class', function()
    local foo = class 'foo' {}
    local f = foo()
    foo.bar = 100
    expect(foo.bar).to.be_equal_to(100)
  end)

  it('should set class field and make it accessible on existing instance', function()
    local foo = class 'foo' {}
    local f = foo()
    foo.bar = 100
    expect(f.bar).to.be_equal_to(100)
  end)

  it('should set class field and make it accessible on new instance', function()
    local foo = class 'foo' {}
    local f = foo()
    foo.bar = 100
    local g = foo()
    expect(g.bar).to.be_equal_to(100)
  end)

  it('should have default tostring starting with class name', function()
    local foo = class 'foo' {}
    local f = foo()
    expect(tostring(f)).to.start_with('foo: ')
  end)

  it('should use custom tostring when provided', function()
    local mock = Mock()
    mock:mockReturnValue('custom tostring')
    local foo = class 'foo' {
      __tostring = mock
    }
    local f = foo()
    expect(tostring(f)).to.be_equal_to('custom tostring')
    expect(mock).to.have_been_called_times(1)
  end)

  it('should call __init with correct arguments', function()
    local mock = Mock()
    local self_ref = Proxy()
    mock:mockImplementation(function(self, arg1, arg2)
      set_proxy_value(self_ref, self)
    end)
    local foo = class 'foo' {
      __init = mock
    }
    local f = foo(1, 2)
    expect(f).to.be_equal_to(self_ref)
    expect(mock).to.have_been_called_times(1)
    local call = mock:get_last_call()
    expect(call.args[2]).to.be_equal_to(1)
    expect(call.args[3]).to.be_equal_to(2)
  end)

  it('should call __new with correct arguments and return value', function()
    local mock = Mock()
    local self_ref = {}
    mock:mockReturnValue(self_ref)
    local foo = class 'foo' {
      __new = mock
    }
    expect(foo(1, 2)).to.be_equal_to(self_ref)
    expect(mock).to.have_been_called_times(1)
    local call = mock:get_last_call()
    expect(call.args[1]).to.be_equal_to(1)
    expect(call.args[2]).to.be_equal_to(2)
  end)

  it('should set property value when setter is provided', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        set=function(self, v)
          self._prop = v
        end,
      }
    }
    local f = foo()
    f.prop = 100
    expect(f._prop).to.be_equal_to(100)
  end)

  it('should throw error when setting property without setter', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        -- No setter
      }
    }
    local f = foo()
    expect(function() f.prop = 100 end).to.throw()
  end)

  it('should get property value when getter is provided', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        get=function(self)
          return self._prop
        end,
      }
    }
    local f = foo()
    f._prop = 100
    expect(f.prop).to.be_equal_to(100)
  end)

  it('should throw error when getting property without getter', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        -- No getter
      }
    }
    local f = foo()
    f._prop = 100
    expect(function() local x = f.prop end).to.throw()
  end)

  it('should get and set property when both getter and setter are provided', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        set=function(self, v)
          self._prop = v
        end,
        get=function(self)
          return self._prop
        end,
      }
    }
    local f = foo()
    f.prop = 100
    expect(f.prop).to.be_equal_to(100)
  end)
end)

describe('derived_class', function()
  it('should have class fields on base class', function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    expect(foo.foo_field).to.be_equal_to(100)
  end)

  it('should not have derived class fields on base class', function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    expect(foo.bar_field).to.be_nil()
  end)

  it('should inherit class fields from base class', function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    expect(bar.foo_field).to.be_equal_to(100)
  end)

  it('should have its own class fields', function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    expect(bar.bar_field).to.be_equal_to(200)
  end)

  it('should have member fields on base class instance', function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    f = foo()
    b = bar()
    expect(f.foo_field).to.be_equal_to(100)
  end)

  it('should not have derived class fields on base class instance', function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    f = foo()
    b = bar()
    expect(f.bar_field).to.be_nil()
  end)

  it('should inherit member fields from base class', function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    f = foo()
    b = bar()
    expect(b.foo_field).to.be_equal_to(100)
  end)

  it('should have its own member fields', function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    f = foo()
    b = bar()
    expect(b.bar_field).to.be_equal_to(200)
  end)

  it('should call base class function from derived class', function()
    local foo_mock = Mock()
    local bar_mock = Mock()
    foo_mock:mockReturnValue(100)
    bar_mock:mockReturnValue(200)
    local foo = class 'foo' {
      foo_func = foo_mock
    }
    local bar = class 'bar' : extends(foo) {
      bar_func = bar_mock
    }
    expect(bar.foo_func()).to.be_equal_to(100)
    expect(foo_mock).to.have_been_called_times(1)
  end)

  it('should call derived class function', function()
    local foo_mock = Mock()
    local bar_mock = Mock()
    foo_mock:mockReturnValue(100)
    bar_mock:mockReturnValue(200)
    local foo = class 'foo' {
      foo_func = foo_mock
    }
    local bar = class 'bar' : extends(foo) {
      bar_func = bar_mock
    }
    expect(bar.bar_func()).to.be_equal_to(200)
    expect(bar_mock).to.have_been_called_times(1)
  end)

  it('should call base class member function from derived instance', function()
    local foo_mock = Mock()
    local bar_mock = Mock()
    foo_mock:mockReturnValue(100)
    bar_mock:mockReturnValue(200)
    local foo = class 'foo' {
      foo_func = foo_mock
    }
    local bar = class 'bar' : extends(foo) {
      bar_func = bar_mock
    }
    b = bar()
    expect(b.foo_func()).to.be_equal_to(100)
    expect(foo_mock).to.have_been_called_times(1)
  end)

  it('should call derived class member function', function()
    local foo_mock = Mock()
    local bar_mock = Mock()
    foo_mock:mockReturnValue(100)
    bar_mock:mockReturnValue(200)
    local foo = class 'foo' {
      foo_func = foo_mock
    }
    local bar = class 'bar' : extends(foo) {
      bar_func = bar_mock
    }
    b = bar()
    expect(b.bar_func()).to.be_equal_to(200)
    expect(bar_mock).to.have_been_called_times(1)
  end)

  it('should set metatable to base class for base instance', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local f = foo()
    local b = bar()
    expect(getmetatable(f)).to.be_equal_to(foo)
  end)

  it('should set metatable to derived class for derived instance', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local f = foo()
    local b = bar()
    expect(getmetatable(b)).to.be_equal_to(bar)
  end)

  it('should set class field on base and make it accessible on base', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    foo.foo_value = 100
    foo.bar_value = 200
    expect(foo.foo_value).to.be_equal_to(100)
  end)

  it('should set class field on base and make it accessible on base with different name', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    foo.foo_value = 100
    foo.bar_value = 200
    expect(foo.bar_value).to.be_equal_to(200)
  end)

  it('should set class field on base and make it accessible on existing derived instance', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    foo.foo_value = 100
    foo.bar_value = 200
    expect(b.foo_value).to.be_equal_to(100)
  end)

  it('should set class field on base and make it accessible on existing derived instance with different name', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    foo.foo_value = 100
    foo.bar_value = 200
    expect(b.bar_value).to.be_equal_to(200)
  end)

  it('should set class field on base and make it accessible on new derived instance', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    foo.foo_value = 100
    foo.bar_value = 200
    local c = bar()
    expect(c.foo_value).to.be_equal_to(100)
  end)

  it('should set class field on base and make it accessible on new derived instance with different name', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    foo.foo_value = 100
    foo.bar_value = 200
    local c = bar()
    expect(c.bar_value).to.be_equal_to(200)
  end)

  it('should have default tostring starting with derived class name', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    expect(tostring(b)).to.start_with('bar: ')
  end)

  it('should use custom tostring from base class', function()
    local mock = Mock()
    mock:mockReturnValue('custom tostring')
    local foo = class 'foo' {
      __tostring = mock
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    expect(tostring(b)).to.be_equal_to('custom tostring')
    expect(mock).to.have_been_called_times(1)
  end)

  it('should use custom tostring from derived class', function()
    local mock = Mock()
    mock:mockReturnValue('custom tostring')
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {
      __tostring = mock
    }
    local b = bar()
    expect(tostring(b)).to.be_equal_to('custom tostring')
    expect(mock).to.have_been_called_times(1)
  end)

  it('should override base class tostring with derived class tostring', function()
    local foo_mock = Mock()
    local bar_mock = Mock()
    bar_mock:mockReturnValue('custom tostring')
    local foo = class 'foo' {
      __tostring = foo_mock
    }
    local bar = class 'bar' : extends(foo) {
      __tostring = bar_mock
    }
    local b = bar()
    expect(tostring(b)).to.be_equal_to('custom tostring')
    expect(foo_mock).to.have_been_called_times(0)
    expect(bar_mock).to.have_been_called_times(1)
  end)

  it('should call __init with self and arguments correctly', function()
    local self_ref = nil
    local a_ref = nil
    local b_ref = nil
    local foo = class 'foo' {
      __init = function(self, arg_a, arg_b)
        self_ref = self
        a_ref = arg_a
        b_ref = arg_b
      end
    }
    local f = foo(1, 2)
    expect(self_ref).to.be_equal_to(f)
  end)

  it('should call __init with first argument correctly', function()
    local self_ref = nil
    local a_ref = nil
    local b_ref = nil
    local foo = class 'foo' {
      __init = function(self, arg_a, arg_b)
        self_ref = self
        a_ref = arg_a
        b_ref = arg_b
      end
    }
    local f = foo(1, 2)
    expect(a_ref).to.be_equal_to(1)
  end)

  it('should call __init with second argument correctly', function()
    local self_ref = nil
    local a_ref = nil
    local b_ref = nil
    local foo = class 'foo' {
      __init = function(self, arg_a, arg_b)
        self_ref = self
        a_ref = arg_a
        b_ref = arg_b
      end
    }
    local f = foo(1, 2)
    expect(b_ref).to.be_equal_to(2)
  end)

  it('should call __new with arguments and return value correctly', function()
    local self_ref = nil
    local a_ref = nil
    local b_ref = nil
    local foo = class 'foo' {
      __new = function(arg_a, arg_b)
        self_ref = {}
        a_ref = arg_a
        b_ref = arg_b
        return self_ref
      end
    }
    local f = foo(1, 2)
    expect(self_ref).to.be_equal_to(f)
  end)

  it('should call __new with first argument correctly', function()
    local self_ref = nil
    local a_ref = nil
    local b_ref = nil
    local foo = class 'foo' {
      __new = function(arg_a, arg_b)
        self_ref = {}
        a_ref = arg_a
        b_ref = arg_b
        return self_ref
      end
    }
    local f = foo(1, 2)
    expect(a_ref).to.be_equal_to(1)
  end)

  it('should call __new with second argument correctly', function()
    local self_ref = nil
    local a_ref = nil
    local b_ref = nil
    local foo = class 'foo' {
      __new = function(arg_a, arg_b)
        self_ref = {}
        a_ref = arg_a
        b_ref = arg_b
        return self_ref
      end
    }
    local f = foo(1, 2)
    expect(b_ref).to.be_equal_to(2)
  end)

  it('should inherit __meta from base class', function()
    local foo = class 'foo' {
      __meta = 'value'
    }
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    expect(foo.__meta).to.be_equal_to('value')
  end)

  it('should inherit __meta to first level derived class', function()
    local foo = class 'foo' {
      __meta = 'value'
    }
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    expect(bar.__meta).to.be_equal_to('value')
  end)

  it('should inherit __meta to second level derived class', function()
    local foo = class 'foo' {
      __meta = 'value'
    }
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    expect(baz.__meta).to.be_equal_to('value')
  end)

  it('should inherit __meta when set late on base class', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    expect(foo.__meta).to.be_equal_to(100)
  end)

  it('should inherit __meta to first level when set late', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    expect(bar.__meta).to.be_equal_to(100)
  end)

  it('should inherit __meta to second level when set late', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    expect(baz.__meta).to.be_equal_to(100)
  end)

  it('should update __meta on base class when changed', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    foo.__meta = 200
    expect(foo.__meta).to.be_equal_to(200)
  end)

  it('should update __meta on first level when base changed', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    foo.__meta = 200
    expect(bar.__meta).to.be_equal_to(200)
  end)

  it('should update __meta on second level when base changed', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    foo.__meta = 200
    expect(baz.__meta).to.be_equal_to(200)
  end)

  it('should allow setting __meta on first level independently', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    bar.__meta = 200
    expect(foo.__meta).to.be_equal_to(100)
  end)

  it('should set __meta on first level when set independently', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    bar.__meta = 200
    expect(bar.__meta).to.be_equal_to(200)
  end)

  it('should inherit __meta from first level to second level when set independently', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    bar.__meta = 200
    expect(baz.__meta).to.be_equal_to(200)
  end)

  it('should allow setting __meta on first level before base', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    bar.__meta = 200
    foo.__meta = 100
    expect(foo.__meta).to.be_equal_to(100)
  end)

  it('should preserve __meta on first level when base set after', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    bar.__meta = 200
    foo.__meta = 100
    expect(bar.__meta).to.be_equal_to(200)
  end)

  it('should inherit __meta from first level to second level when base set after', function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    bar.__meta = 200
    foo.__meta = 100
    expect(baz.__meta).to.be_equal_to(200)
  end)

  it('should update __meta on ancestor when changed', function()
    local ancestor = class 'foo' {}
    local descendant = ancestor
    for i=1, 10 do
      descendant = class : extends(descendant) {}
    end
    ancestor.__meta = 100
    ancestor.__meta = 200
    expect(ancestor.__meta).to.be_equal_to(200)
  end)

  it('should update __meta on descendant when ancestor changed', function()
    local ancestor = class 'foo' {}
    local descendant = ancestor
    for i=1, 10 do
      descendant = class : extends(descendant) {}
    end
    ancestor.__meta = 100
    ancestor.__meta = 200
    expect(descendant.__meta).to.be_equal_to(200)
  end)

  it('should set property value when setter is provided in base class', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        set=function(self, v)
          self._prop = v
        end,
      }
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    b.prop = 100
    expect(b._prop).to.be_equal_to(100)
  end)

  it('should throw error when setting property without setter in base class', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        -- No setter
      }
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    expect(function() b.prop = 100 end).to.throw()
  end)

  it('should get property value when getter is provided in base class', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        get=function(self)
          return self._prop
        end,
      }
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    b._prop = 100
    expect(b.prop).to.be_equal_to(100)
  end)

  it('should throw error when getting property without getter in base class', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        -- No getter
      }
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    b._prop = 100
    expect(function() local x = b.prop end).to.throw()
  end)

  it('should get and set property when both getter and setter are provided in base class', function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        set=function(self, v)
          self._prop = v
        end,
        get=function(self)
          return self._prop
        end,
      }
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    b.prop = 100
    expect(b.prop).to.be_equal_to(100)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

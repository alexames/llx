local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local property = require 'llx.property'
local proxy = require 'llx.proxy'
local unit = require 'unit'

local test_class = unit.test_class
local class = class_module.class
local Proxy = proxy.Proxy
local set_proxy_value = proxy.set_proxy_value

local function CallSpec(t)
  return t
end

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


test_class 'class' {
  ['class_fields' | test] = function()
    local foo = class 'foo' {
      field = 100
    }
    EXPECT_EQ(foo.field, 100)
  end,

  ['member_fields' | test] = function()
    local foo = class 'foo' {
      field = 100
    }
    local f = foo()
    EXPECT_EQ(f.field, 100)
  end,

  ['class_functions' | test] = function()
    local mock <close> = Mock()
    local foo = class 'foo' {
      func = mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={100}}
      }
    }
    EXPECT_EQ(foo.func(), 100)
  end,

  ['member_functions' | test] = function()
    local mock <close> = Mock()
    local self_ref = Proxy()
    local foo = class 'foo' {
      func = mock:call_count(Equals(1)):call_spec{
        CallSpec{expected_args={ProxySetter(self_ref)},
                 return_values={100}}
      }
    }
    local f = foo()
    EXPECT_EQ(f:func(), 100)
    EXPECT_EQ(f, self_ref)
  end,

  ['metatable' | test] = function()
    local foo = class 'foo' {}
    local f = foo()
    EXPECT_EQ(getmetatable(f), foo)
  end,

  ['set_instance_field' | test] = function()
    local foo = class 'foo' {}
    local f = foo()
    f.bar = 100
    EXPECT_EQ(f.bar, 100)
  end,

  ['set_class_field' | test] = function()
    local foo = class 'foo' {}
    local f = foo()
    foo.bar = 100
    local g = foo()
    EXPECT_EQ(foo.bar, 100)
    EXPECT_EQ(f.bar, 100)
    EXPECT_EQ(g.bar, 100)
  end,

  ['default_tostring' | test] = function()
    local foo = class 'foo' {}
    local f = foo()
    EXPECT_THAT(tostring(f), StartsWith('foo: '))
  end,

  ['custom_tostring' | test] = function()
    local mock <close> = Mock()
    local foo = class 'foo' {
      __tostring = mock:call_spec {
        CallSpec{return_values={'custom tostring'}}
      }
    }
    local f = foo()
    EXPECT_EQ(tostring(f), 'custom tostring')
  end,

  ['init' | test] = function()
    local mock <close> = Mock()
    local self_ref = Proxy()
    local foo = class 'foo' {
      __init = mock:call_spec{
        CallSpec{expected_args={
          ProxySetter(self_ref), Equals(1), Equals(2)}}
      }
    }
    local f = foo(1, 2)
    EXPECT_EQ(f, self_ref)
  end,

  ['new' | test] = function()
    local mock <close> = Mock()
    local self_ref = {}
    local foo = class 'foo' {
      __new = mock:call_spec{
        CallSpec{expected_args = {Equals(1), Equals(2)},
                 return_values={self_ref}}
      }
    }
    EXPECT_EQ(foo(1, 2), self_ref)
  end,

  ['property - setter - success' | test] = function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        set=function(self, v)
          self._prop = v
        end,
      }
    }
    local f = foo()
    f.prop = 100
    EXPECT_EQ(f._prop, 100)
  end,

  ['property - setter - failure' | test] = function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        -- No setter
      }
    }
    local f = foo()
    EXPECT_ERROR(function() f.prop = 100 end)
  end,

  ['property - getter - success' | test] = function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        get=function(self)
          return self._prop
        end,
      }
    }
    local f = foo()
    f._prop = 100
    EXPECT_EQ(f.prop, 100)
  end,

  ['property - getter - failure' | test] = function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        -- No getter
      }
    }
    local f = foo()
    f._prop = 100
    EXPECT_ERROR(function() local x = f.prop end)
  end,

  ['property - both' | test] = function()
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
    EXPECT_EQ(f.prop, 100)
  end,
}

test_class 'derived_class' {
  ['class_fields' | test] = function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    EXPECT_EQ(foo.foo_field, 100)
    EXPECT_EQ(foo.bar_field, nil)
    EXPECT_EQ(bar.foo_field, 100)
    EXPECT_EQ(bar.bar_field, 200)
  end,

  ['member_fields' | test] = function()
    local foo = class 'foo' {
      foo_field = 100
    }
    local bar = class 'bar' : extends(foo) {
      bar_field = 200
    }
    f = foo()
    b = bar()
    EXPECT_EQ(f.foo_field, 100)
    EXPECT_EQ(f.bar_field, nil)
    EXPECT_EQ(b.foo_field, 100)
    EXPECT_EQ(b.bar_field, 200)
  end,

  ['class_functions' | test] = function()
    local foo_mock <close> = Mock()
    local bar_mock <close> = Mock()
    local foo = class 'foo' {
      foo_func = foo_mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={100}}
      }
    }
    local bar = class 'bar' : extends(foo) {
      bar_func = bar_mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={200}}
      }
    }
    EXPECT_EQ(bar.foo_func(), 100)
    EXPECT_EQ(bar.bar_func(), 200)
  end,

  ['member_functions' | test] = function()
    local foo_mock <close> = Mock()
    local bar_mock <close> = Mock()
    local foo = class 'foo' {
      foo_func = foo_mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={100}}
      }
    }
    local bar = class 'bar' : extends(foo) {
      bar_func = bar_mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={200}}
      }
    }
    b = bar()
    EXPECT_EQ(b.foo_func(), 100)
    EXPECT_EQ(b.bar_func(), 200)
  end,

  ['metatable' | test] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local f = foo()
    local b = bar()
    EXPECT_EQ(getmetatable(f), foo)
    EXPECT_EQ(getmetatable(b), bar)
  end,

  ['set_class_field' | test] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    foo.foo_value = 100
    foo.bar_value = 200
    local c = bar()
    EXPECT_EQ(foo.foo_value, 100)
    EXPECT_EQ(foo.bar_value, 200)
    EXPECT_EQ(b.foo_value, 100)
    EXPECT_EQ(b.bar_value, 200)
    EXPECT_EQ(c.foo_value, 100)
    EXPECT_EQ(c.bar_value, 200)
  end,

  ['default_tostring' | test] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    EXPECT_THAT(tostring(b), StartsWith('bar: '))
  end,

  ['custom_tostring' | test] = function()
    local mock <close> = Mock()
    local foo = class 'foo' {
      __tostring = mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={'custom tostring'}}
      }
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    EXPECT_EQ(tostring(b), 'custom tostring')
  end,

  ['custom_tostring_on_derived' | test] = function()
    local mock <close> = Mock()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {
      __tostring = mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={'custom tostring'}}
      }
    }
    local b = bar()
    EXPECT_EQ(tostring(b), 'custom tostring')
  end,

  ['custom_tostring_override' | test] = function()
    local foo_mock <close> = Mock()
    local bar_mock <close> = Mock()
    local foo = class 'foo' {
      __tostring = foo_mock:call_count(Equals(0)):call_spec{}
    }
    local bar = class 'bar' : extends(foo) {
      __tostring = bar_mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={'custom tostring'}}
      }
    }
    local b = bar()
    EXPECT_EQ(tostring(b), 'custom tostring')
  end,

--------------------------------------------------------------------------------
  ['init' | test] = function()
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
    EXPECT_EQ(self_ref, f)
    EXPECT_EQ(a_ref, 1)
    EXPECT_EQ(b_ref, 2)
  end,

--------------------------------------------------------------------------------
  ['new' | test] = function()
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
    EXPECT_EQ(self_ref, f)
    EXPECT_EQ(a_ref, 1)
    EXPECT_EQ(b_ref, 2)
  end,

  ['descendant_metainheritance' | test] = function()
    local foo = class 'foo' {
      __meta = 'value'
    }
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    EXPECT_EQ(foo.__meta, 'value')
    EXPECT_EQ(bar.__meta, 'value')
    EXPECT_EQ(baz.__meta, 'value')
  end,

  ['descendant_metainheritance_late' | test] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    EXPECT_EQ(foo.__meta, 100)
    EXPECT_EQ(bar.__meta, 100)
    EXPECT_EQ(baz.__meta, 100)
  end,

  ['descendant_metainheritance_changed' | test] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    foo.__meta = 200
    EXPECT_EQ(foo.__meta, 200)
    EXPECT_EQ(bar.__meta, 200)
    EXPECT_EQ(baz.__meta, 200)
  end,

  ['descendant_metainheritance_changed_intercepted' | test] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    bar.__meta = 200
    EXPECT_EQ(foo.__meta, 100)
    EXPECT_EQ(bar.__meta, 200)
    EXPECT_EQ(baz.__meta, 200)
  end,

  ['descendant_metainheritance_changed_intercepted_out_of_order' | test] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    bar.__meta = 200
    foo.__meta = 100
    EXPECT_EQ(foo.__meta, 100)
    EXPECT_EQ(bar.__meta, 200)
    EXPECT_EQ(baz.__meta, 200)
  end,

  ['descendant_metainheritance_descendant' | test] = function()
    local ancestor = class 'foo' {}
    local descendant = ancestor
    for i=1, 10 do
      descendant = class : extends(descendant) {}
    end
    ancestor.__meta = 100
    ancestor.__meta = 200
    -- descendant.__meta = 100
    EXPECT_EQ(ancestor.__meta, 200)
    EXPECT_EQ(descendant.__meta, 200)
  end,

  ['property - setter - success' | test] = function()
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
    EXPECT_EQ(b._prop, 100)
  end,

  ['property - setter - failure' | test] = function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        -- No setter
      }
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    EXPECT_ERROR(function() b.prop = 100 end)
  end,

  ['property - getter - success' | test] = function()
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
    EXPECT_EQ(b.prop, 100)
  end,

  ['property - getter - failure' | test] = function()
    local foo = class 'foo' {
      ['prop' | property.property] = {
        -- No getter
      }
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    b._prop = 100
    EXPECT_ERROR(function() local x = b.prop end)
  end,

  ['property - both' | test] = function()
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
    EXPECT_EQ(b.prop, 100)
  end,

}

if llx.main_file() then
  unit.run_unit_tests()
end

local unit = require 'unit'
require 'llx/core/class'
require 'llx/core/proxy'

local function CallSpec(t)
  return t
end

function ProxySetter(proxy)
  return function(v)
    set_proxy_value(proxy, v)
    return true
  end
end

test_class 'class' {
  [test 'class_fields'] = function()
    local foo = class 'foo' {
      field = 100
    }
    EXPECT_EQ(foo.field, 100)
  end,

  [test 'member_fields'] = function()
    local foo = class 'foo' {
      field = 100
    }
    local f = foo()
    EXPECT_EQ(f.field, 100)
  end,

  [test 'class_functions'] = function()
    local mock <close> = Mock()
    local foo = class 'foo' {
      func = mock:call_count(Equals(1)):call_spec{
        CallSpec{return_values={100}}
      }
    }
    EXPECT_EQ(foo.func(), 100)
  end,

  [test 'member_functions'] = function()
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

  [test 'metatable'] = function()
    local foo = class 'foo' {}
    local f = foo()
    EXPECT_EQ(getmetatable(f), foo)
  end,

  [test 'set_instance_field'] = function()
    local foo = class 'foo' {}
    local f = foo()
    f.bar = 100
    EXPECT_EQ(f.bar, 100)
  end,

  [test 'set_class_field'] = function()
    local foo = class 'foo' {}
    local f = foo()
    foo.bar = 100
    local g = foo()
    EXPECT_EQ(foo.bar, 100)
    EXPECT_EQ(f.bar, 100)
    EXPECT_EQ(g.bar, 100)
  end,

  [test 'default_tostring'] = function()
    local foo = class 'foo' {}
    local f = foo()
    EXPECT_THAT(tostring(f), StartsWith('foo: '))
  end,

  [test 'custom_tostring'] = function()
    local mock <close> = Mock()
    local foo = class 'foo' {
      __tostring = mock:call_spec {
        CallSpec{return_values={'custom tostring'}}
      }
    }
    local f = foo()
    EXPECT_EQ(tostring(f), 'custom tostring')
  end,

  [test 'init'] = function()
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

  [test 'new'] = function()
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

}

test_class 'derived_class' {
  [test 'class_fields'] = function()
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

  [test 'member_fields'] = function()
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

  [test 'class_functions'] = function()
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

  [test 'member_functions'] = function()
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

  [test 'metatable'] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local f = foo()
    local b = bar()
    EXPECT_EQ(getmetatable(f), foo)
    EXPECT_EQ(getmetatable(b), bar)
  end,

  [test 'set_class_field'] = function()
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

  [test 'default_tostring'] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    EXPECT_THAT(tostring(b), StartsWith('bar: '))
  end,

  [test 'custom_tostring'] = function()
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

  [test 'custom_tostring_on_derived'] = function()
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

  [test 'custom_tostring_override'] = function()
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
  [test 'init'] = function()
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
  [test 'new'] = function()
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

  [test 'descendant_metainheritance'] = function()
    local foo = class 'foo' {
      __meta = 'value'
    }
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    EXPECT_EQ(foo.__meta, 'value')
    EXPECT_EQ(bar.__meta, 'value')
    EXPECT_EQ(baz.__meta, 'value')
  end,

  [test 'descendant_metainheritance_late'] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    EXPECT_EQ(foo.__meta, 100)
    EXPECT_EQ(bar.__meta, 100)
    EXPECT_EQ(baz.__meta, 100)
  end,

  [test 'descendant_metainheritance_changed'] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    foo.__meta = 200
    EXPECT_EQ(foo.__meta, 200)
    EXPECT_EQ(bar.__meta, 200)
    EXPECT_EQ(baz.__meta, 200)
  end,

  [test 'descendant_metainheritance_changed_intercepted'] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    foo.__meta = 100
    bar.__meta = 200
    EXPECT_EQ(foo.__meta, 100)
    EXPECT_EQ(bar.__meta, 200)
    EXPECT_EQ(baz.__meta, 200)
  end,

  [test 'descendant_metainheritance_changed_intercepted_out_of_order'] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local baz = class 'baz' : extends(bar) {}
    bar.__meta = 200
    foo.__meta = 100
    EXPECT_EQ(foo.__meta, 100)
    EXPECT_EQ(bar.__meta, 200)
    EXPECT_EQ(baz.__meta, 200)
  end,

  [test 'descendant_metainheritance_descendant'] = function()
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

}
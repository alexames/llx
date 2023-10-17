require 'lx/unit'
class = require 'lx/class'

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


-- function TestCase(name)
--   return function(args)
--     return class(name):extends(TestCase)(args)
--   end
-- end

test_class 'class' {
  [test('class_fields')] = function()
    local foo = class 'foo' {
      field = 100
    }
    EXPECT_EQ(foo.field, 100)
  end;
  [test('member_fields')] = function()
    local foo = class 'foo' {
      field = 100
    }
    local f = foo()
    EXPECT_EQ(f.field, 100)
  end;
  [test('class_functions')] = function()
    -- TODO: proper mocks
    local called = false
    local foo = class 'foo' {
      func = function()
        called = true
        return 100
      end;
    }
    EXPECT_EQ(foo.func(), 100)
    EXPECT_TRUE(called)
  end;
  [test('member_functions')] = function()
    -- TODO: proper mocks
    local called = false
    local self_ref = nil
    local foo = class 'foo' {
      func = function(self)
        called = true
        self_ref = self
        return 100
      end;
    }
    local f = foo()
    EXPECT_EQ(f:func(), 100)
    EXPECT_EQ(self_ref, f)
    EXPECT_TRUE(called)
  end;
  [test('metatable')] = function()
    local foo = class 'foo' {}
    local f = foo()
    EXPECT_EQ(getmetatable(f), foo)
  end;
  [test('set_instance_field')] = function()
    local foo = class 'foo' {}
    local f = foo()
    f.bar = 100
    EXPECT_EQ(f.bar, 100)
  end;
  [test('set_class_field')] = function()
    local foo = class 'foo' {}
    local f = foo()
    foo.bar = 100
    local g = foo()
    EXPECT_EQ(foo.bar, 100)
    EXPECT_EQ(f.bar, 100)
    EXPECT_EQ(g.bar, 100)
  end;
  [test('default_tostring')] = function()
    local foo = class 'foo' {}
    local f = foo()
    EXPECT_THAT(tostring(f), StartsWith('foo: '))
  end;
  [test('custom_tostring')] = function()
    local foo = class 'foo' {
      __tostring = function(self)
        return 'custom tostring'
      end
    }
    local f = foo()
    EXPECT_EQ(tostring(f), 'custom tostring')
  end;
  [test('init')] = function()
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
  end;
  [test('new')] = function()
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
  end;
}

test_class 'derived_class' {
  [test('class_fields')] = function()
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
  end;
  [test('member_fields')] = function()
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
  end;
  [test('class_functions')] = function()
    local foo_called = false
    local bar_called = false
    local foo = class 'foo' {
      foo_func = function()
        foo_called = true
        return 100
      end;
    }
    local bar = class 'bar' : extends(foo) {
      bar_func = function()
        bar_called = true
        return 200
      end;
    }
    EXPECT_EQ(bar.foo_func(), 100)
    EXPECT_TRUE(foo_called)
    EXPECT_EQ(bar.bar_func(), 200)
    EXPECT_TRUE(bar_called)
  end;
  [test('member_functions')] = function()
    local foo_called = false
    local bar_called = false
    local foo = class 'foo' {
      foo_func = function()
        foo_called = true
        return 100
      end;
    }
    local bar = class 'bar' : extends(foo) {
      bar_func = function()
        bar_called = true
        return 200
      end;
    }
    b = bar()
    EXPECT_EQ(b.foo_func(), 100)
    EXPECT_TRUE(foo_called)
    EXPECT_EQ(b.bar_func(), 200)
    EXPECT_TRUE(bar_called)
  end;
  [test('metatable')] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local f = foo()
    local b = bar()
    EXPECT_EQ(getmetatable(f), foo)
    EXPECT_EQ(getmetatable(b), bar)
  end;
  [test('set_class_field')] = function()
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
  end;
  [test('default_tostring')] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    EXPECT_THAT(tostring(b), StartsWith('bar: '))
  end;
  [test('custom_tostring')] = function()
    local foo = class 'foo' {
      __tostring = function(self)
        return 'custom tostring'
      end
    }
    local bar = class 'bar' : extends(foo) {}
    local b = bar()
    EXPECT_EQ(tostring(b), 'custom tostring')
  end;
  [test('custom_tostring_on_derived')] = function()
    local foo = class 'foo' {}
    local bar = class 'bar' : extends(foo) {
      __tostring = function(self)
        return 'custom tostring'
      end
    }
    local b = bar()
    EXPECT_EQ(tostring(b), 'custom tostring')
  end;
  [test('custom_tostring_override')] = function()
    local foo = class 'foo' {
      __tostring = function(self)
        return 'wrong tostring'
      end
    }
    local bar = class 'bar' : extends(foo) {
      __tostring = function(self)
        return 'right tostring'
      end
    }
    local b = bar()
    EXPECT_EQ(tostring(b), 'right tostring')
  end;
--------------------------------------------------------------------------------
  [test('init')] = function()
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
  end;
--------------------------------------------------------------------------------
  [test('new')] = function()
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
  end;
}
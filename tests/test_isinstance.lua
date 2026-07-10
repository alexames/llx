local unit = require 'llx.unit'
local llx = require 'llx'

local isinstance = require 'llx.isinstance' . isinstance
local class = require 'llx.class' . class
local types = require 'llx.types'

_ENV = unit.create_test_env(_ENV)

describe('isinstance', function()
  describe('with built-in type tables', function()
    it('should return true for a string checked against String', function()
      expect(isinstance('hello', types.String)).to.be_true()
    end)

    it('should return true for an empty string checked '
      .. 'against String', function()
      expect(isinstance('', types.String)).to.be_true()
    end)

    it('should return true for a number checked against Number', function()
      expect(isinstance(42, types.Number)).to.be_true()
    end)

    it('should return true for a float checked against Number', function()
      expect(isinstance(3.14, types.Number)).to.be_true()
    end)

    it('should return true for zero checked against Number', function()
      expect(isinstance(0, types.Number)).to.be_true()
    end)

    it('should return true for a boolean checked against Boolean', function()
      expect(isinstance(true, types.Boolean)).to.be_true()
    end)

    it('should return true for false checked against Boolean', function()
      expect(isinstance(false, types.Boolean)).to.be_true()
    end)

    it('should return true for a table checked against Table', function()
      expect(isinstance({}, types.Table)).to.be_true()
    end)

    it('should return true for nil checked against Nil', function()
      expect(isinstance(nil, types.Nil)).to.be_true()
    end)

    it('should return true for a function checked against Function', function()
      expect(isinstance(function() end, types.Function)).to.be_true()
    end)

    it('should return true for a coroutine checked against Thread', function()
      local co = coroutine.create(function() end)
      expect(isinstance(co, types.Thread)).to.be_true()
    end)
  end)

  describe('with mismatched built-in types', function()
    it('should return false for a string checked against Number', function()
      expect(isinstance('hello', types.Number)).to.be_false()
    end)

    it('should return false for a number checked against String', function()
      expect(isinstance(42, types.String)).to.be_false()
    end)

    it('should return false for a boolean checked against Number', function()
      expect(isinstance(true, types.Number)).to.be_false()
    end)

    it('should return false for nil checked against String', function()
      expect(isinstance(nil, types.String)).to.be_false()
    end)

    it('should return false for a table checked against String', function()
      expect(isinstance({}, types.String)).to.be_false()
    end)

    it('should return false for a function checked against Table', function()
      expect(isinstance(function() end, types.Table)).to.be_false()
    end)

    it('should return false for a number checked against Boolean', function()
      expect(isinstance(0, types.Boolean)).to.be_false()
    end)

    it('should return false for a string checked against Nil', function()
      expect(isinstance('hello', types.Nil)).to.be_false()
    end)
  end)

  describe('with class instances', function()
    it('should return true for an instance of a class', function()
      local Foo = class 'Foo' {}
      local f = Foo()
      expect(isinstance(f, Foo)).to.be_true()
    end)

    it('should return false for an instance of a different class', function()
      local Foo = class 'Foo' {}
      local Bar = class 'Bar' {}
      local f = Foo()
      expect(isinstance(f, Bar)).to.be_false()
    end)

    it('should return true for an instance checked '
      .. 'against its base class', function()
      local Base = class 'Base' {}
      local Derived = class 'Derived' : extends(Base) {}
      local d = Derived()
      expect(isinstance(d, Base)).to.be_true()
    end)

    it('should return true for an instance checked '
      .. 'against its own derived class', function()
      local Base = class 'Base' {}
      local Derived = class 'Derived' : extends(Base) {}
      local d = Derived()
      expect(isinstance(d, Derived)).to.be_true()
    end)

    it('should return false for a base class instance '
      .. 'checked against a derived class', function()
      local Base = class 'Base' {}
      local Derived = class 'Derived' : extends(Base) {}
      local b = Base()
      expect(isinstance(b, Derived)).to.be_false()
    end)

    it('should return true for a deeply inherited instance '
      .. 'checked against the root class', function()
      local A = class 'A' {}
      local B = class 'B' : extends(A) {}
      local C = class 'C' : extends(B) {}
      local c = C()
      expect(isinstance(c, A)).to.be_true()
    end)

    it('should return true for a deeply inherited instance '
      .. 'checked against the middle class', function()
      local A = class 'A' {}
      local B = class 'B' : extends(A) {}
      local C = class 'C' : extends(B) {}
      local c = C()
      expect(isinstance(c, B)).to.be_true()
    end)
  end)

  describe('with non-matcher type arguments', function()
    -- The type argument must be a matcher or class carrying
    -- __isinstance; anything else raises a clear
    -- InvalidArgumentException naming argument #2 instead of failing
    -- with an obscure index error (numbers, nil) or silently
    -- returning false (strings, tables without __isinstance).
    local InvalidArgumentException =
        llx.exceptions.InvalidArgumentException

    local function expect_bad_type_error(value, bad_type)
      local ok, err = pcall(isinstance, value, bad_type)
      expect(ok).to.be_false()
      expect(isinstance(err, InvalidArgumentException)).to.be_true()
      expect(err.what:find('bad argument #2', 1, true)).to_not.be_nil()
      expect(err.what:find(
          'expected a type matcher or class with __isinstance',
          1, true)).to_not.be_nil()
    end

    it('should raise when the type table has no __isinstance', function()
      expect_bad_type_error('hello', {})
    end)

    it('should raise for a type table with a name '
      .. 'but no __isinstance', function()
      expect_bad_type_error(42, { __name = 'FakeType' })
    end)

    it('should raise for a string type argument, naming it', function()
      local ok, err = pcall(isinstance, 42, 'MyClass')
      expect(ok).to.be_false()
      expect(err.what:find("got string 'MyClass'", 1, true))
          .to_not.be_nil()
    end)

    it('should raise for a number type argument, naming it', function()
      local ok, err = pcall(isinstance, 42, 5)
      expect(ok).to.be_false()
      expect(err.what:find('got number 5', 1, true)).to_not.be_nil()
    end)

    it('should raise for a nil type argument', function()
      expect_bad_type_error(42, nil)
    end)
  end)

  describe('with custom __isinstance metamethod', function()
    it('should use the custom __isinstance function', function()
      local EvenNumber = {
        __isinstance = function(self, value)
          return type(value) == 'number' and value % 2 == 0
        end
      }
      expect(isinstance(4, EvenNumber)).to.be_true()
      expect(isinstance(3, EvenNumber)).to.be_false()
    end)

    it('should support Any type that matches everything', function()
      expect(isinstance('hello', types.Any)).to.be_true()
      expect(isinstance(42, types.Any)).to.be_true()
      expect(isinstance(nil, types.Any)).to.be_true()
      expect(isinstance({}, types.Any)).to.be_true()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

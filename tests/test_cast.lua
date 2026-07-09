local unit = require 'llx.unit'
local llx = require 'llx'

local cast_module = require 'llx.cast'
local cast = cast_module.cast
local try_cast = cast_module.try_cast

local class = require 'llx.class' . class
local exceptions = require 'llx.exceptions'
local TypeError = exceptions.TypeError
local isinstance = require 'llx.isinstance' . isinstance
local result_module = require 'llx.result'
local Result = result_module.Result
local types = require 'llx.types'
local Union = types.Union
local Optional = types.Optional
local Protocol = types.Protocol

_ENV = unit.create_test_env(_ENV)

describe('cast', function()
  describe('on success', function()
    it('should return the identical table value', function()
      local t = {}
      expect(rawequal(cast(t, types.Table), t)).to.be_true()
    end)

    it('should return the value for a string', function()
      expect(cast('hello', types.String)).to.be_equal_to('hello')
    end)

    it('should return the value for a number', function()
      expect(cast(42, types.Number)).to.be_equal_to(42)
    end)

    it('should return false unchanged for a boolean', function()
      expect(cast(false, types.Boolean)).to.be_false()
    end)

    it('should return nil for a nil checked against Nil', function()
      expect(cast(nil, types.Nil)).to.be_nil()
    end)

    it('should return a class instance checked against '
      .. 'its own class', function()
      local Foo = class 'Foo' {}
      local f = Foo()
      expect(rawequal(cast(f, Foo), f)).to.be_true()
    end)

    it('should return a derived instance checked against '
      .. 'its base class', function()
      local Base = class 'Base' {}
      local Derived = class 'Derived' : extends(Base) {}
      local d = Derived()
      expect(rawequal(cast(d, Base), d)).to.be_true()
    end)
  end)

  describe('on failure', function()
    it('should raise for a string checked against Number', function()
      expect(function() cast('hello', types.Number) end).to.throw()
    end)

    it('should raise a TypeError', function()
      local ok, exception = pcall(cast, 'hello', types.Number)
      expect(ok).to.be_false()
      expect(isinstance(exception, TypeError)).to.be_true()
    end)

    it('should name the expected and actual types '
      .. 'in the message', function()
      local ok, exception = pcall(cast, 'hello', types.Number)
      expect(ok).to.be_false()
      expect(exception.what).to.be_equal_to(
          'Number expected, got String')
    end)

    it('should raise for a base instance checked against '
      .. 'a derived class', function()
      local Base = class 'Base' {}
      local Derived = class 'Derived' : extends(Base) {}
      local b = Base()
      expect(function() cast(b, Derived) end).to.throw()
    end)

    it('should raise a TypeError when the type is nil', function()
      local ok, exception = pcall(cast, 42, nil)
      expect(ok).to.be_false()
      expect(isinstance(exception, TypeError)).to.be_true()
    end)
  end)

  describe('with matchers', function()
    it('should accept a value matching a Union member', function()
      local NumberOrString = Union{types.Number, types.String}
      expect(cast('hi', NumberOrString)).to.be_equal_to('hi')
      expect(cast(7, NumberOrString)).to.be_equal_to(7)
    end)

    it('should raise for a value outside a Union', function()
      local NumberOrString = Union{types.Number, types.String}
      expect(function() cast(true, NumberOrString) end).to.throw()
    end)

    it('should accept nil for an Optional type', function()
      expect(cast(nil, Optional(types.Number))).to.be_nil()
    end)

    it('should accept a present value for an Optional type', function()
      expect(cast(3, Optional(types.Number))).to.be_equal_to(3)
    end)

    it('should raise for a mismatched Optional value', function()
      expect(function() cast('x', Optional(types.Number)) end)
        .to.throw()
    end)

    it('should accept a value matching a Protocol shape', function()
      local Named = Protocol{name = types.String}
      local value = {name = 'llx'}
      expect(rawequal(cast(value, Named), value)).to.be_true()
    end)

    it('should raise for a value missing a Protocol field', function()
      local Named = Protocol{name = types.String}
      expect(function() cast({}, Named) end).to.throw()
    end)
  end)
end)

describe('try_cast', function()
  describe('on success', function()
    it('should return an Ok Result', function()
      local r = try_cast(42, types.Number)
      expect(isinstance(r, Result)).to.be_true()
      expect(r:is_ok()).to.be_true()
    end)

    it('should wrap the identical value', function()
      local t = {}
      local r = try_cast(t, types.Table)
      expect(rawequal(r:unwrap(), t)).to.be_true()
    end)

    it('should work with Union matchers', function()
      local NumberOrString = Union{types.Number, types.String}
      expect(try_cast('hi', NumberOrString):unwrap())
        .to.be_equal_to('hi')
    end)

    it('should work with Optional matchers', function()
      local r = try_cast(nil, Optional(types.Number))
      expect(r:is_ok()).to.be_true()
      expect(r:unwrap()).to.be_nil()
    end)

    it('should work with Protocol matchers', function()
      local Named = Protocol{name = types.String}
      local value = {name = 'llx'}
      expect(try_cast(value, Named):is_ok()).to.be_true()
    end)
  end)

  describe('on failure', function()
    it('should return an Err Result', function()
      local r = try_cast('hello', types.Number)
      expect(isinstance(r, Result)).to.be_true()
      expect(r:is_err()).to.be_true()
    end)

    it('should wrap a TypeError with a useful message', function()
      local r = try_cast('hello', types.Number)
      local exception = r:unwrap_err()
      expect(isinstance(exception, TypeError)).to.be_true()
      expect(exception.what).to.be_equal_to(
          'Number expected, got String')
    end)

    it('should return Err for a value outside a Union', function()
      local NumberOrString = Union{types.Number, types.String}
      expect(try_cast(true, NumberOrString):is_err()).to.be_true()
    end)

    it('should return Err for a value violating a Protocol', function()
      local Named = Protocol{name = types.String}
      expect(try_cast({name = 42}, Named):is_err()).to.be_true()
    end)

    it('should raise (not return Err) when the type is nil', function()
      expect(function() try_cast(42, nil) end).to.throw()
    end)
  end)
end)

describe('llx module exports', function()
  it('should expose cast and try_cast at the top level', function()
    expect(llx.cast).to.be_equal_to(cast)
    expect(llx.try_cast).to.be_equal_to(try_cast)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

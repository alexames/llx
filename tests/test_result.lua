local unit = require 'llx.unit'
local llx = require 'llx'
local result_module = require 'llx.result'

local Result = result_module.Result
local Ok = result_module.Ok
local Err = result_module.Err
local Option = result_module.Option
local Some = result_module.Some
local None = result_module.None

local hash = require 'llx.hash' . hash
local isinstance = require 'llx.isinstance' . isinstance

_ENV = unit.create_test_env(_ENV)

describe('Result', function()
  describe('construction', function()
    it('Ok should create an Ok variant', function()
      local r = Ok(42)
      expect(r:is_ok()).to.be_true()
      expect(r:is_err()).to.be_false()
    end)

    it('Err should create an Err variant', function()
      local r = Err('failed')
      expect(r:is_err()).to.be_true()
      expect(r:is_ok()).to.be_false()
    end)

    it('both should be instances of Result', function()
      expect(isinstance(Ok(1), Result)).to.be_true()
      expect(isinstance(Err('x'), Result)).to.be_true()
    end)
  end)

  describe('unwrap', function()
    it('should return the value from Ok', function()
      expect(Ok(42):unwrap()).to.be_equal_to(42)
    end)

    it('should raise on Err', function()
      expect(function() Err('boom'):unwrap() end).to.throw()
    end)

    it('unwrap_or should return value on Ok', function()
      expect(Ok(42):unwrap_or(0)).to.be_equal_to(42)
    end)

    it('unwrap_or should return default on Err', function()
      expect(Err('x'):unwrap_or(99)).to.be_equal_to(99)
    end)

    it('unwrap_err should return error on Err', function()
      expect(Err('boom'):unwrap_err()).to.be_equal_to('boom')
    end)

    it('unwrap_err should raise on Ok', function()
      expect(function() Ok(1):unwrap_err() end).to.throw()
    end)
  end)

  describe('map and map_err', function()
    it('map should transform Ok', function()
      expect(Ok(2):map(function(x) return x * 10 end):unwrap())
        .to.be_equal_to(20)
    end)

    it('map should pass through Err', function()
      local r = Err('x'):map(function(x) return x * 10 end)
      expect(r:is_err()).to.be_true()
      expect(r:unwrap_err()).to.be_equal_to('x')
    end)

    it('map_err should transform Err', function()
      local r = Err('boom'):map_err(function(e) return 'wrapped: ' .. e end)
      expect(r:unwrap_err()).to.be_equal_to('wrapped: boom')
    end)

    it('map_err should pass through Ok', function()
      local r = Ok(5):map_err(function(e) return 'never' end)
      expect(r:unwrap()).to.be_equal_to(5)
    end)
  end)

  describe('and_then and or_else (monadic bind)', function()
    it('and_then should chain on Ok', function()
      local r = Ok(2):and_then(function(x) return Ok(x + 1) end)
      expect(r:unwrap()).to.be_equal_to(3)
    end)

    it('and_then should short-circuit on Err', function()
      local called = false
      local r = Err('x'):and_then(function(x) called = true; return Ok(x) end)
      expect(called).to.be_false()
      expect(r:is_err()).to.be_true()
    end)

    it('or_else should recover from Err', function()
      local r = Err('x'):or_else(function(e) return Ok('recovered') end)
      expect(r:unwrap()).to.be_equal_to('recovered')
    end)

    it('or_else should pass through Ok', function()
      local called = false
      local r = Ok(1):or_else(function() called = true; return Err('x') end)
      expect(called).to.be_false()
      expect(r:unwrap()).to.be_equal_to(1)
    end)
  end)

  describe('Result.try', function()
    it('should wrap a normal return as Ok', function()
      local r = Result.try(function() return 42 end)
      expect(r:is_ok()).to.be_true()
      expect(r:unwrap()).to.be_equal_to(42)
    end)

    it('should wrap an error as Err', function()
      local r = Result.try(function() error('boom') end)
      expect(r:is_err()).to.be_true()
      -- Lua's error() prepends "file:line: " to plain strings; just
      -- check the message contains the original text.
      expect(r:unwrap_err()).to.contain('boom')
    end)

    it('should forward arguments to fn', function()
      local r = Result.try(function(a, b) return a + b end, 3, 4)
      expect(r:unwrap()).to.be_equal_to(7)
    end)

    it('should capture an Exception raised via error()', function()
      local exceptions = llx.exceptions
      local r = Result.try(function()
        error(exceptions.ValueException('bad input'))
      end)
      expect(r:is_err()).to.be_true()
      -- The Err wraps the raised exception object.
      local err = r:unwrap_err()
      expect(err.what).to.contain('bad input')
    end)
  end)

  describe('__eq, __hash, __tostring', function()
    it('Ok values should compare equal by inner value', function()
      expect(Ok(42) == Ok(42)).to.be_true()
      expect(Ok(1) == Ok(2)).to.be_false()
    end)

    it('Err values should compare equal by inner value', function()
      expect(Err('x') == Err('x')).to.be_true()
    end)

    it('Ok and Err with same inner should not compare equal', function()
      expect(Ok('x') == Err('x')).to.be_false()
    end)

    it('should hash equal Ok values to the same hash', function()
      expect(hash(Ok(42))).to.be_equal_to(hash(Ok(42)))
    end)

    it('should produce a readable tostring', function()
      expect(tostring(Ok(42))).to.be_equal_to('Ok(42)')
      expect(tostring(Err('boom'))).to.be_equal_to('Err(boom)')
    end)
  end)
end)

describe('Option', function()
  describe('construction', function()
    it('Some should create a Some variant', function()
      expect(Some(42):is_some()).to.be_true()
      expect(Some(42):is_none()).to.be_false()
    end)

    it('None should be a None variant', function()
      expect(None:is_none()).to.be_true()
      expect(None:is_some()).to.be_false()
    end)

    it('both should be instances of Option', function()
      expect(isinstance(Some(1), Option)).to.be_true()
      expect(isinstance(None, Option)).to.be_true()
    end)
  end)

  describe('unwrap', function()
    it('should return the value from Some', function()
      expect(Some(42):unwrap()).to.be_equal_to(42)
    end)

    it('should raise on None', function()
      expect(function() None:unwrap() end).to.throw()
    end)

    it('unwrap_or should return value on Some', function()
      expect(Some(5):unwrap_or(0)).to.be_equal_to(5)
    end)

    it('unwrap_or should return default on None', function()
      expect(None:unwrap_or(99)).to.be_equal_to(99)
    end)
  end)

  describe('map and bind', function()
    it('map should transform Some', function()
      expect(Some(3):map(function(x) return x * 2 end):unwrap())
        .to.be_equal_to(6)
    end)

    it('map should pass through None', function()
      expect(None:map(function(x) return x * 2 end):is_none()).to.be_true()
    end)

    it('and_then should chain on Some', function()
      local r = Some(3):and_then(function(x) return Some(x + 1) end)
      expect(r:unwrap()).to.be_equal_to(4)
    end)

    it('and_then should short-circuit on None', function()
      local called = false
      local r = None:and_then(function() called = true; return Some(1) end)
      expect(called).to.be_false()
    end)

    it('or_else should recover from None', function()
      local r = None:or_else(function() return Some('recovered') end)
      expect(r:unwrap()).to.be_equal_to('recovered')
    end)

    it('or_else should pass through Some', function()
      local called = false
      local r = Some(1):or_else(function() called = true end)
      expect(called).to.be_false()
      expect(r:unwrap()).to.be_equal_to(1)
    end)
  end)

  describe('Option.from_nilable', function()
    it('should return None for nil', function()
      expect(Option.from_nilable(nil):is_none()).to.be_true()
    end)

    it('should return Some for any non-nil value', function()
      expect(Option.from_nilable(42):unwrap()).to.be_equal_to(42)
      expect(Option.from_nilable('hi'):unwrap()).to.be_equal_to('hi')
      expect(Option.from_nilable({}):is_some()).to.be_true()
    end)

    it('should treat false as a value, not absence', function()
      local o = Option.from_nilable(false)
      expect(o:is_some()).to.be_true()
      expect(o:unwrap()).to.be_equal_to(false)
    end)

    it('should treat zero and empty string as values', function()
      expect(Option.from_nilable(0):unwrap()).to.be_equal_to(0)
      expect(Option.from_nilable(''):unwrap()).to.be_equal_to('')
    end)
  end)

  describe('ok_or (Option to Result)', function()
    it('Some should become Ok', function()
      local r = Some(42):ok_or('missing')
      expect(r:is_ok()).to.be_true()
      expect(r:unwrap()).to.be_equal_to(42)
    end)

    it('None should become Err', function()
      local r = None:ok_or('missing')
      expect(r:is_err()).to.be_true()
      expect(r:unwrap_err()).to.be_equal_to('missing')
    end)
  end)

  describe('__eq, __hash, __tostring', function()
    it('Some values should compare equal by inner value', function()
      expect(Some(42) == Some(42)).to.be_true()
      expect(Some(1) == Some(2)).to.be_false()
    end)

    it('None should compare equal to itself', function()
      expect(None == None).to.be_true()
    end)

    it('Some and None should never compare equal', function()
      expect(Some(nil) == None).to.be_false()
    end)

    it('should hash equal Some values to the same hash', function()
      expect(hash(Some(42))).to.be_equal_to(hash(Some(42)))
    end)

    it('should produce readable tostring', function()
      expect(tostring(Some(42))).to.be_equal_to('Some(42)')
      expect(tostring(None)).to.be_equal_to('None')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.operators'

_ENV = unit.create_test_env(_ENV)

describe('operators (tier 3)', function()
  describe('attrgetter', function()
    it('should access a simple attribute', function()
      local get_name = llx.operators.attrgetter('name')
      expect(get_name({name = 'Alice'})).to.be_equal_to('Alice')
    end)

    it('should access nested attributes with dot path', function()
      local get_city = llx.operators.attrgetter('address.city')
      local obj = {address = {city = 'NYC'}}
      expect(get_city(obj)).to.be_equal_to('NYC')
    end)

    it('should return nil for missing path', function()
      local get_deep = llx.operators.attrgetter('a.b.c')
      expect(get_deep({a = {}})).to.be_equal_to(nil)
    end)
  end)

  describe('methodcaller', function()
    it('should call a named method', function()
      local call_upper = llx.operators.methodcaller('upper')
      expect(call_upper('hello')).to.be_equal_to('HELLO')
    end)

    it('should pass extra arguments to the method', function()
      local call_rep = llx.operators.methodcaller('rep', 3)
      expect(call_rep('ab')).to.be_equal_to('ababab')
    end)
  end)

  describe('not_', function()
    it('should negate truthy values', function()
      expect(llx.operators.not_(true)).to.be_equal_to(false)
    end)

    it('should negate falsy values', function()
      expect(llx.operators.not_(false)).to.be_equal_to(true)
      expect(llx.operators.not_(nil)).to.be_equal_to(true)
    end)
  end)

  describe('and_', function()
    it('should return second value when both truthy', function()
      expect(llx.operators.and_(1, 2)).to.be_equal_to(2)
    end)

    it('should return first falsy value', function()
      expect(llx.operators.and_(false, 2)).to.be_equal_to(false)
      expect(llx.operators.and_(nil, 2)).to.be_equal_to(nil)
    end)
  end)

  describe('or_', function()
    it('should return first truthy value', function()
      expect(llx.operators.or_(1, 2)).to.be_equal_to(1)
    end)

    it('should return second value when first is falsy', function()
      expect(llx.operators.or_(false, 2)).to.be_equal_to(2)
      expect(llx.operators.or_(nil, 'fallback')).to.be_equal_to('fallback')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

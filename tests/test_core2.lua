-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.functional'

_ENV = unit.create_test_env(_ENV)

describe('core utilities (tier 3)', function()
  describe('type predicates', function()
    it('is_table should detect tables', function()
      expect(llx.is_table({})).to.be_equal_to(true)
      expect(llx.is_table(1)).to.be_equal_to(false)
    end)

    it('is_string should detect strings', function()
      expect(llx.is_string('hello')).to.be_equal_to(true)
      expect(llx.is_string(1)).to.be_equal_to(false)
    end)

    it('is_number should detect numbers', function()
      expect(llx.is_number(42)).to.be_equal_to(true)
      expect(llx.is_number('42')).to.be_equal_to(false)
    end)

    it('is_function should detect functions', function()
      expect(llx.is_function(print)).to.be_equal_to(true)
      expect(llx.is_function(42)).to.be_equal_to(false)
    end)

    it('is_boolean should detect booleans', function()
      expect(llx.is_boolean(true)).to.be_equal_to(true)
      expect(llx.is_boolean(false)).to.be_equal_to(true)
      expect(llx.is_boolean(nil)).to.be_equal_to(false)
    end)

    it('is_nil should detect nil', function()
      expect(llx.is_nil(nil)).to.be_equal_to(true)
      expect(llx.is_nil(false)).to.be_equal_to(false)
    end)
  end)

  describe('clone', function()
    it('should shallow copy a table', function()
      local t = {a = 1, b = {c = 2}}
      local c = llx.clone(t)
      expect(c.a).to.be_equal_to(1)
      expect(c.b).to.be_equal_to(t.b)  -- same reference (shallow)
      c.a = 99
      expect(t.a).to.be_equal_to(1)  -- original unchanged
    end)

    it('should return non-table values unchanged', function()
      expect(llx.clone(42)).to.be_equal_to(42)
      expect(llx.clone('hello')).to.be_equal_to('hello')
      expect(llx.clone(true)).to.be_equal_to(true)
    end)
  end)

  describe('times', function()
    it('should call function n times and collect results', function()
      local result = llx.times(3, function(i) return i * 10 end)
      expect(result).to.be_equal_to(llx.List{10, 20, 30})
    end)

    it('should return empty list for n=0', function()
      local result = llx.times(0, function() return 1 end)
      expect(#result).to.be_equal_to(0)
    end)
  end)

  describe('cond', function()
    it('should return result of first matching predicate', function()
      local classify = llx.cond({
        {function(x) return x < 0 end, function() return 'negative' end},
        {function(x) return x == 0 end, function() return 'zero' end},
        {function() return true end, function() return 'positive' end},
      })
      expect(classify(-5)).to.be_equal_to('negative')
      expect(classify(0)).to.be_equal_to('zero')
      expect(classify(5)).to.be_equal_to('positive')
    end)

    it('should return nil when no predicate matches', function()
      local f = llx.cond({
        {function(x) return x > 100 end, function() return 'big' end},
      })
      expect(f(1)).to.be_equal_to(nil)
    end)
  end)

  describe('collect', function()
    it('should materialize an iterator into a List', function()
      local result = llx.collect(llx.functional.range(5))
      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4})
    end)

    it('should handle empty iterator', function()
      local result = llx.collect(llx.functional.range(1))
      expect(#result).to.be_equal_to(0)
    end)
  end)

  describe('range_inclusive', function()
    it('should include the end value', function()
      local result = llx.List{}
      for _, v in llx.functional.range_inclusive(1, 5) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)

    it('should work with step', function()
      local result = llx.List{}
      for _, v in llx.functional.range_inclusive(0, 10, 3) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{0, 3, 6, 9})
    end)

    it('should work with single argument', function()
      local result = llx.List{}
      for _, v in llx.functional.range_inclusive(3) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

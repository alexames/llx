-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.mathx'

_ENV = unit.create_test_env(_ENV)

describe('mathx (tier 2)', function()
  describe('gcd', function()
    it('should compute the greatest common divisor', function()
      expect(llx.mathx.gcd(12, 8)).to.be_equal_to(4)
    end)

    it('should return the other value when one is zero', function()
      expect(llx.mathx.gcd(0, 5)).to.be_equal_to(5)
      expect(llx.mathx.gcd(7, 0)).to.be_equal_to(7)
    end)

    it('should handle equal values', function()
      expect(llx.mathx.gcd(6, 6)).to.be_equal_to(6)
    end)

    it('should handle coprime numbers', function()
      expect(llx.mathx.gcd(7, 13)).to.be_equal_to(1)
    end)
  end)

  describe('lcm', function()
    it('should compute the least common multiple', function()
      expect(llx.mathx.lcm(4, 6)).to.be_equal_to(12)
    end)

    it('should return 0 when either argument is 0', function()
      expect(llx.mathx.lcm(0, 5)).to.be_equal_to(0)
    end)

    it('should handle equal values', function()
      expect(llx.mathx.lcm(7, 7)).to.be_equal_to(7)
    end)
  end)

  describe('factorial', function()
    it('should compute factorial of small numbers', function()
      expect(llx.mathx.factorial(5)).to.be_equal_to(120)
    end)

    it('should return 1 for 0', function()
      expect(llx.mathx.factorial(0)).to.be_equal_to(1)
    end)

    it('should return 1 for 1', function()
      expect(llx.mathx.factorial(1)).to.be_equal_to(1)
    end)

    it('should compute factorial of 10', function()
      expect(llx.mathx.factorial(10)).to.be_equal_to(3628800)
    end)
  end)

  describe('in_range', function()
    it('should return true when value is in range', function()
      expect(llx.mathx.in_range(5, 0, 10)).to.be_true()
    end)

    it('should return true for lower bound (inclusive)', function()
      expect(llx.mathx.in_range(0, 0, 10)).to.be_true()
    end)

    it('should return false for upper bound (exclusive)', function()
      expect(llx.mathx.in_range(10, 0, 10)).to.be_false()
    end)

    it('should return false for values below range', function()
      expect(llx.mathx.in_range(-1, 0, 10)).to.be_false()
    end)
  end)

  describe('remap', function()
    it('should map a value from one range to another', function()
      expect(llx.mathx.remap(5, 0, 10, 0, 100)).to.be_equal_to(50)
    end)

    it('should handle boundary values', function()
      expect(llx.mathx.remap(0, 0, 10, 20, 40)).to.be_equal_to(20)
      expect(llx.mathx.remap(10, 0, 10, 20, 40)).to.be_equal_to(40)
    end)

    it('should handle inverted output range', function()
      expect(llx.mathx.remap(0, 0, 10, 100, 0)).to.be_equal_to(100)
      expect(llx.mathx.remap(10, 0, 10, 100, 0)).to.be_equal_to(0)
    end)
  end)

  describe('divmod', function()
    it('should return quotient and remainder', function()
      local q, r = llx.mathx.divmod(7, 3)
      expect(q).to.be_equal_to(2)
      expect(r).to.be_equal_to(1)
    end)

    it('should return 0 remainder for even division', function()
      local q, r = llx.mathx.divmod(10, 5)
      expect(q).to.be_equal_to(2)
      expect(r).to.be_equal_to(0)
    end)

    it('should handle negative dividend', function()
      local q, r = llx.mathx.divmod(-7, 3)
      expect(q).to.be_equal_to(-3)
      expect(r).to.be_equal_to(2)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.mathx'

_ENV = unit.create_test_env(_ENV)

describe('mathx', function()
  describe('clamp', function()
    it('should return the value when within range', function()
      expect(llx.mathx.clamp(5, 0, 10)).to.be_equal_to(5)
    end)

    it('should return lo when value is below range', function()
      expect(llx.mathx.clamp(-5, 0, 10)).to.be_equal_to(0)
    end)

    it('should return hi when value is above range', function()
      expect(llx.mathx.clamp(15, 0, 10)).to.be_equal_to(10)
    end)

    it('should return boundary when value equals boundary', function()
      expect(llx.mathx.clamp(0, 0, 10)).to.be_equal_to(0)
      expect(llx.mathx.clamp(10, 0, 10)).to.be_equal_to(10)
    end)
  end)

  describe('round', function()
    it('should round to the nearest integer by default', function()
      expect(llx.mathx.round(3.7)).to.be_equal_to(4)
      expect(llx.mathx.round(3.2)).to.be_equal_to(3)
    end)

    it('should round 0.5 away from zero', function()
      expect(llx.mathx.round(2.5)).to.be_equal_to(3)
      expect(llx.mathx.round(-2.5)).to.be_equal_to(-3)
    end)

    it('should round to specified decimal places', function()
      expect(llx.mathx.round(3.14159, 2)).to.be_equal_to(3.14)
      expect(llx.mathx.round(3.14159, 4)).to.be_equal_to(3.1416)
    end)

    it('should handle negative precision', function()
      expect(llx.mathx.round(1234, -2)).to.be_equal_to(1200)
    end)
  end)

  describe('preconditions', function()
    it('clamp should reject lo > hi', function()
      expect(function() llx.mathx.clamp(5, 10, 0) end).to.throw()
    end)

    it('mean should reject empty sequence', function()
      expect(function() llx.mathx.mean({}) end).to.throw()
    end)

    it('median should reject empty sequence', function()
      expect(function() llx.mathx.median({}) end).to.throw()
    end)

    it('variance should reject sequence with fewer than 2 elements', function()
      expect(function() llx.mathx.variance({1}) end).to.throw()
    end)

    it('pvariance should reject empty sequence', function()
      expect(function() llx.mathx.pvariance({}) end).to.throw()
    end)

    it('factorial should reject negative numbers', function()
      expect(function() llx.mathx.factorial(-1) end).to.throw()
    end)

    it('factorial should reject non-integers', function()
      expect(function() llx.mathx.factorial(2.5) end).to.throw()
    end)

    it('remap should reject degenerate input range', function()
      expect(function() llx.mathx.remap(5, 10, 10, 0, 100) end).to.throw()
    end)

    it('inverse_lerp should reject identical endpoints', function()
      expect(function() llx.mathx.inverse_lerp(5, 5, 5) end).to.throw()
    end)

    it('wrap_around should reject hi <= lo', function()
      expect(function() llx.mathx.wrap_around(5, 10, 10) end).to.throw()
    end)

    it('harmonic_mean should reject empty sequence', function()
      expect(function() llx.mathx.harmonic_mean({}) end).to.throw()
    end)

    it('harmonic_mean should reject non-positive elements', function()
      expect(function() llx.mathx.harmonic_mean({1, -2, 3}) end).to.throw()
    end)

    it('geometric_mean should reject empty sequence', function()
      expect(function() llx.mathx.geometric_mean({}) end).to.throw()
    end)

    it('geometric_mean should reject non-positive elements', function()
      expect(function() llx.mathx.geometric_mean({1, 0, 3}) end).to.throw()
    end)

    it('mode should reject empty sequence', function()
      expect(function() llx.mathx.mode({}) end).to.throw()
    end)

    it('quantile should reject empty sequence', function()
      expect(function() llx.mathx.quantile({}, 0.5) end).to.throw()
    end)

    it('quantile should reject q outside [0,1]', function()
      expect(function() llx.mathx.quantile({1,2,3}, -0.1) end).to.throw()
      expect(function() llx.mathx.quantile({1,2,3}, 1.1) end).to.throw()
    end)
  end)

  describe('sign', function()
    it('should return 1 for positive numbers', function()
      expect(llx.mathx.sign(5)).to.be_equal_to(1)
    end)

    it('should return -1 for negative numbers', function()
      expect(llx.mathx.sign(-5)).to.be_equal_to(-1)
    end)

    it('should return 0 for zero', function()
      expect(llx.mathx.sign(0)).to.be_equal_to(0)
    end)
  end)

  describe('lerp', function()
    it('should return a when t is 0', function()
      expect(llx.mathx.lerp(10, 20, 0)).to.be_equal_to(10)
    end)

    it('should return b when t is 1', function()
      expect(llx.mathx.lerp(10, 20, 1)).to.be_equal_to(20)
    end)

    it('should return midpoint when t is 0.5', function()
      expect(llx.mathx.lerp(10, 20, 0.5)).to.be_equal_to(15)
    end)

    it('should extrapolate beyond the range', function()
      expect(llx.mathx.lerp(0, 10, 2)).to.be_equal_to(20)
    end)
  end)

  describe('mean', function()
    it('should compute the arithmetic mean', function()
      expect(llx.mathx.mean({1, 2, 3, 4, 5})).to.be_equal_to(3)
    end)

    it('should handle a single element', function()
      expect(llx.mathx.mean({7})).to.be_equal_to(7)
    end)

    it('should handle floating point values', function()
      expect(llx.mathx.mean({1.5, 2.5})).to.be_equal_to(2)
    end)
  end)

  describe('median', function()
    it('should return the middle value for odd-length sequences', function()
      expect(llx.mathx.median({3, 1, 2})).to.be_equal_to(2)
    end)

    it('should return the average of two middle values '
      .. 'for even-length', function()
      expect(llx.mathx.median({1, 2, 3, 4})).to.be_equal_to(2.5)
    end)

    it('should handle a single element', function()
      expect(llx.mathx.median({5})).to.be_equal_to(5)
    end)

    it('should not modify the original table', function()
      local data = {3, 1, 2}
      llx.mathx.median(data)
      expect(data[1]).to.be_equal_to(3)
    end)
  end)

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

    it('should avoid intermediate overflow by dividing '
      .. 'before multiplying', function()
      -- Two large numbers whose product would overflow but whose LCM fits
      local a = 2^40
      local b = 2^40 * 3
      expect(llx.mathx.lcm(a, b)).to.be_equal_to(2^40 * 3)
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

  describe('mode', function()
    it('should return the most common value', function()
      expect(llx.mathx.mode({1, 2, 2, 3, 3, 3})).to.be_equal_to(3)
    end)

    it('should return the first most-common value for ties', function()
      expect(llx.mathx.mode({1, 1, 2, 2})).to.be_equal_to(1)
    end)

    it('should handle a single element', function()
      expect(llx.mathx.mode({42})).to.be_equal_to(42)
    end)
  end)

  describe('variance', function()
    it('should compute sample variance', function()
      -- sample variance of {2, 4, 4, 4, 5, 5, 7, 9} = 4.571428...
      local result = llx.mathx.variance({2, 4, 4, 4, 5, 5, 7, 9})
      expect(result > 4.57 and result < 4.58).to.be_true()
    end)

    it('should return 0 for identical values', function()
      expect(llx.mathx.variance({5, 5, 5, 5})).to.be_equal_to(0)
    end)
  end)

  describe('pvariance', function()
    it('should compute population variance', function()
      -- population variance of {2, 4, 4, 4, 5, 5, 7, 9} = 4.0
      expect(llx.mathx.pvariance({2, 4, 4, 4, 5, 5, 7, 9})).to.be_equal_to(4)
    end)
  end)

  describe('stdev', function()
    it('should compute sample standard deviation', function()
      local result = llx.mathx.stdev({2, 4, 4, 4, 5, 5, 7, 9})
      -- sqrt(4.571428...) ≈ 2.138
      expect(result > 2.13 and result < 2.14).to.be_true()
    end)
  end)

  describe('pstdev', function()
    it('should compute population standard deviation', function()
      -- sqrt(4.0) = 2.0
      expect(llx.mathx.pstdev({2, 4, 4, 4, 5, 5, 7, 9})).to.be_equal_to(2)
    end)
  end)

  describe('is_nan', function()
    it('should return true for NaN', function()
      expect(llx.mathx.is_nan(0/0)).to.be_equal_to(true)
    end)

    it('should return false for normal numbers', function()
      expect(llx.mathx.is_nan(42)).to.be_equal_to(false)
    end)

    it('should return false for infinity', function()
      expect(llx.mathx.is_nan(math.huge)).to.be_equal_to(false)
    end)
  end)

  describe('is_inf', function()
    it('should return true for positive infinity', function()
      expect(llx.mathx.is_inf(math.huge)).to.be_equal_to(true)
    end)

    it('should return true for negative infinity', function()
      expect(llx.mathx.is_inf(-math.huge)).to.be_equal_to(true)
    end)

    it('should return false for normal numbers', function()
      expect(llx.mathx.is_inf(42)).to.be_equal_to(false)
    end)

    it('should return false for NaN', function()
      expect(llx.mathx.is_inf(0/0)).to.be_equal_to(false)
    end)
  end)

  describe('wrap_around', function()
    it('should wrap value above range', function()
      expect(llx.mathx.wrap_around(12, 0, 10)).to.be_equal_to(2)
    end)

    it('should wrap value below range', function()
      expect(llx.mathx.wrap_around(-1, 0, 10)).to.be_equal_to(9)
    end)

    it('should leave value within range unchanged', function()
      expect(llx.mathx.wrap_around(5, 0, 10)).to.be_equal_to(5)
    end)

    it('should handle angles wrapping around 360', function()
      expect(llx.mathx.wrap_around(370, 0, 360)).to.be_equal_to(10)
    end)
  end)

  describe('inverse_lerp', function()
    it('should return 0 at start', function()
      expect(llx.mathx.inverse_lerp(0, 10, 0)).to.be_equal_to(0)
    end)

    it('should return 1 at end', function()
      expect(llx.mathx.inverse_lerp(0, 10, 10)).to.be_equal_to(1)
    end)

    it('should return 0.5 at midpoint', function()
      expect(llx.mathx.inverse_lerp(0, 10, 5)).to.be_equal_to(0.5)
    end)
  end)

  describe('harmonic_mean', function()
    it('should compute harmonic mean', function()
      local result = llx.mathx.harmonic_mean({1, 4, 4})
      expect(result).to.be_equal_to(2)
    end)

    it('should compute harmonic mean of equal values', function()
      local result = llx.mathx.harmonic_mean({5, 5, 5})
      expect(llx.mathx.round(result, 10)).to.be_equal_to(5)
    end)
  end)

  describe('geometric_mean', function()
    it('should compute geometric mean', function()
      local result = llx.mathx.geometric_mean({1, 9})
      expect(llx.mathx.round(result, 10)).to.be_equal_to(3)
    end)

    it('should compute geometric mean of equal values', function()
      local result = llx.mathx.geometric_mean({4, 4, 4})
      expect(result).to.be_equal_to(4)
    end)

    it('should compute geometric mean of powers of 2', function()
      local result = llx.mathx.geometric_mean({2, 8})
      expect(result).to.be_equal_to(4)
    end)
  end)

  describe('quantile', function()
    it('should return min at q=0', function()
      expect(llx.mathx.quantile({1, 2, 3, 4, 5}, 0)).to.be_equal_to(1)
    end)

    it('should return max at q=1', function()
      expect(llx.mathx.quantile({1, 2, 3, 4, 5}, 1)).to.be_equal_to(5)
    end)

    it('should return median at q=0.5', function()
      expect(llx.mathx.quantile({1, 2, 3, 4, 5}, 0.5)).to.be_equal_to(3)
    end)

    it('should interpolate between values', function()
      local result = llx.mathx.quantile({1, 2, 3, 4}, 0.25)
      expect(result).to.be_equal_to(1.75)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

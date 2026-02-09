-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.mathx'

_ENV = unit.create_test_env(_ENV)

describe('mathx (tier 3)', function()
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

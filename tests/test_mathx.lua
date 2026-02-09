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

    it('should return the average of two middle values for even-length', function()
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
end)

if llx.main_file() then
  unit.run_unit_tests()
end

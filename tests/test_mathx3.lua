-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.mathx'

_ENV = unit.create_test_env(_ENV)

describe('mathx statistics', function()
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
end)

if llx.main_file() then
  unit.run_unit_tests()
end

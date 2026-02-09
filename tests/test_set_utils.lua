-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.set'
require 'llx.types.list'

_ENV = unit.create_test_env(_ENV)

describe('set utilities', function()
  describe('symmetric_difference', function()
    it('should return elements in either set but not both', function()
      local a = llx.Set{1, 2, 3}
      local b = llx.Set{2, 3, 4}
      local result = a:symmetric_difference(b)
      expect(result).to.be_equal_to(llx.Set{1, 4})
    end)

    it('should return union for disjoint sets', function()
      local a = llx.Set{1, 2}
      local b = llx.Set{3, 4}
      local result = a:symmetric_difference(b)
      expect(result).to.be_equal_to(llx.Set{1, 2, 3, 4})
    end)

    it('should return empty set for identical sets', function()
      local a = llx.Set{1, 2, 3}
      local b = llx.Set{1, 2, 3}
      local result = a:symmetric_difference(b)
      expect(result).to.be_equal_to(llx.Set{})
    end)

    it('should be accessible via __bxor operator', function()
      local a = llx.Set{1, 2, 3}
      local b = llx.Set{2, 3, 4}
      local result = a ~ b
      expect(result).to.be_equal_to(llx.Set{1, 4})
    end)
  end)

  describe('is_subset', function()
    it('should return true when all elements are in the other set', function()
      local a = llx.Set{1, 2}
      local b = llx.Set{1, 2, 3}
      expect(a:is_subset(b)).to.be_true()
    end)

    it('should return true for equal sets', function()
      local a = llx.Set{1, 2, 3}
      local b = llx.Set{1, 2, 3}
      expect(a:is_subset(b)).to.be_true()
    end)

    it('should return false when an element is missing', function()
      local a = llx.Set{1, 2, 4}
      local b = llx.Set{1, 2, 3}
      expect(a:is_subset(b)).to.be_false()
    end)

    it('should return true for empty set', function()
      local a = llx.Set{}
      local b = llx.Set{1, 2, 3}
      expect(a:is_subset(b)).to.be_true()
    end)
  end)

  describe('is_superset', function()
    it('should return true when set contains all elements of other', function()
      local a = llx.Set{1, 2, 3}
      local b = llx.Set{1, 2}
      expect(a:is_superset(b)).to.be_true()
    end)

    it('should return false when an element is missing', function()
      local a = llx.Set{1, 2}
      local b = llx.Set{1, 2, 3}
      expect(a:is_superset(b)).to.be_false()
    end)
  end)

  describe('is_disjoint', function()
    it('should return true when sets share no elements', function()
      local a = llx.Set{1, 2}
      local b = llx.Set{3, 4}
      expect(a:is_disjoint(b)).to.be_true()
    end)

    it('should return false when sets share at least one element', function()
      local a = llx.Set{1, 2, 3}
      local b = llx.Set{3, 4, 5}
      expect(a:is_disjoint(b)).to.be_false()
    end)

    it('should return true for two empty sets', function()
      local a = llx.Set{}
      local b = llx.Set{}
      expect(a:is_disjoint(b)).to.be_true()
    end)
  end)

  describe('len', function()
    it('should return the number of elements', function()
      local s = llx.Set{1, 2, 3}
      expect(s:len()).to.be_equal_to(3)
    end)

    it('should return 0 for empty set', function()
      local s = llx.Set{}
      expect(s:len()).to.be_equal_to(0)
    end)

    it('should update after insert and remove', function()
      local s = llx.Set{1, 2}
      expect(s:len()).to.be_equal_to(2)
      s:insert(3)
      expect(s:len()).to.be_equal_to(3)
      s:remove(1)
      expect(s:len()).to.be_equal_to(2)
    end)
  end)

  describe('contains', function()
    it('should return true for present elements', function()
      local s = llx.Set{1, 2, 3}
      expect(s:contains(2)).to.be_true()
    end)

    it('should return false for absent elements', function()
      local s = llx.Set{1, 2, 3}
      expect(s:contains(5)).to.be_false()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

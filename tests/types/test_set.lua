-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'
local unit = require 'llx.unit'
local Set = require 'llx.types.set' . Set

local describe = unit.describe
local it = unit.it
local expect = unit.expect

describe('Set', function()
  describe('construction', function()
    it('should create empty set', function()
      local s = Set{}
      expect(#s).to.be_equal_to(0)
    end)

    it('should create set from list', function()
      local s = Set{1, 2, 3}
      expect(#s).to.be_equal_to(3)
      expect(s:contains(1)).to.be_equal_to(true)
      expect(s:contains(2)).to.be_equal_to(true)
      expect(s:contains(3)).to.be_equal_to(true)
    end)

    it('should create set with mixed types', function()
      local s = Set{1, 'a', true}
      expect(#s).to.be_equal_to(3)
      expect(s:contains(1)).to.be_equal_to(true)
      expect(s:contains('a')).to.be_equal_to(true)
      expect(s:contains(true)).to.be_equal_to(true)
    end)

    it('should deduplicate elements', function()
      local s = Set{1, 2, 1, 3, 2}
      expect(#s).to.be_equal_to(3)
    end)
  end)

  describe('contains', function()
    local s = Set{1, 2, 3}

    it('should return true for members', function()
      expect(s:contains(1)).to.be_equal_to(true)
      expect(s:contains(2)).to.be_equal_to(true)
      expect(s:contains(3)).to.be_equal_to(true)
    end)

    it('should return false for non-members', function()
      expect(s:contains(4)).to.be_equal_to(false)
      expect(s:contains(0)).to.be_equal_to(false)
      expect(s:contains('1')).to.be_equal_to(false)
    end)
  end)

  describe('insert', function()
    it('should add element to set', function()
      local s = Set{1, 2}
      s:insert(3)
      expect(#s).to.be_equal_to(3)
      expect(s:contains(3)).to.be_equal_to(true)
    end)

    it('should not increase size for duplicate', function()
      local s = Set{1, 2}
      s:insert(1)
      expect(#s).to.be_equal_to(2)
    end)
  end)

  describe('remove', function()
    it('should remove element from set', function()
      local s = Set{1, 2, 3}
      s:remove(2)
      expect(#s).to.be_equal_to(2)
      expect(s:contains(2)).to.be_equal_to(false)
      expect(s:contains(1)).to.be_equal_to(true)
    end)

    it('should handle removing non-existent element', function()
      local s = Set{1, 2}
      s:remove(99)
      expect(#s).to.be_equal_to(2)
    end)
  end)

  describe('union', function()
    it('should combine two sets', function()
      local a = Set{1, 2, 3}
      local b = Set{3, 4, 5}
      local result = a:union(b)
      expect(#result).to.be_equal_to(5)
      for i=1, 5 do
        expect(result:contains(i)).to.be_equal_to(true)
      end
    end)

    it('should not modify original sets', function()
      local a = Set{1, 2}
      local b = Set{3}
      a:union(b)
      expect(#a).to.be_equal_to(2)
      expect(a:contains(3)).to.be_equal_to(false)
    end)

    it('should support | operator', function()
      local a = Set{1, 2}
      local b = Set{2, 3}
      local result = a | b
      expect(#result).to.be_equal_to(3)
    end)
  end)

  describe('intersection', function()
    it('should find common elements', function()
      local a = Set{1, 2, 3}
      local b = Set{2, 3, 4}
      local result = a:intersection(b)
      expect(#result).to.be_equal_to(2)
      expect(result:contains(2)).to.be_equal_to(true)
      expect(result:contains(3)).to.be_equal_to(true)
    end)

    it('should return empty set for disjoint sets', function()
      local a = Set{1, 2}
      local b = Set{3, 4}
      local result = a:intersection(b)
      expect(#result).to.be_equal_to(0)
    end)

    it('should support & operator', function()
      local a = Set{1, 2, 3}
      local b = Set{2, 3}
      local result = a & b
      expect(#result).to.be_equal_to(2)
    end)
  end)

  describe('difference', function()
    it('should remove elements in other set', function()
      local a = Set{1, 2, 3}
      local b = Set{2}
      local result = a:difference(b)
      expect(#result).to.be_equal_to(2)
      expect(result:contains(1)).to.be_equal_to(true)
      expect(result:contains(3)).to.be_equal_to(true)
      expect(result:contains(2)).to.be_equal_to(false)
    end)

    it('should return copy when other set is disjoint', function()
      local a = Set{1, 2}
      local b = Set{3, 4}
      local result = a:difference(b)
      expect(#result).to.be_equal_to(2)
    end)

    it('should support - operator', function()
      local a = Set{1, 2, 3}
      local b = Set{2}
      local result = a - b
      expect(#result).to.be_equal_to(2)
    end)
  end)

  describe('symmetric_difference', function()
    it('should find elements in either set but not both', function()
      local a = Set{1, 2, 3}
      local b = Set{2, 3, 4}
      local result = a:symmetric_difference(b)
      expect(#result).to.be_equal_to(2)
      expect(result:contains(1)).to.be_equal_to(true)
      expect(result:contains(4)).to.be_equal_to(true)
    end)

    it('should support ~ operator', function()
      local a = Set{1, 2}
      local b = Set{2, 3}
      local result = a ~ b
      expect(#result).to.be_equal_to(2)
    end)
  end)

  describe('subset/superset', function()
    it('should identify subsets', function()
      local a = Set{1, 2}
      local b = Set{1, 2, 3}
      expect(a:is_subset(b)).to.be_equal_to(true)
      expect(b:is_subset(a)).to.be_equal_to(false)
    end)

    it('should identify equal sets as subsets', function()
      local a = Set{1, 2}
      local b = Set{1, 2}
      expect(a:is_subset(b)).to.be_equal_to(true)
    end)

    it('should identify supersets', function()
      local a = Set{1, 2, 3}
      local b = Set{1, 2}
      expect(a:is_superset(b)).to.be_equal_to(true)
      expect(b:is_superset(a)).to.be_equal_to(false)
    end)
  end)

  describe('disjoint', function()
    it('should identify disjoint sets', function()
      local a = Set{1, 2}
      local b = Set{3, 4}
      expect(a:is_disjoint(b)).to.be_equal_to(true)
    end)

    it('should return false for overlapping sets', function()
      local a = Set{1, 2}
      local b = Set{2, 3}
      expect(a:is_disjoint(b)).to.be_equal_to(false)
    end)
  end)

  describe('copy', function()
    it('should create independent copy', function()
      local original = Set{1, 2, 3}
      local copy = original:copy()
      copy:insert(4)
      expect(#original).to.be_equal_to(3)
      expect(#copy).to.be_equal_to(4)
    end)

    it('should preserve elements', function()
      local original = Set{1, 2, 3}
      local copy = original:copy()
      expect(copy:contains(1)).to.be_equal_to(true)
      expect(copy:contains(2)).to.be_equal_to(true)
      expect(copy:contains(3)).to.be_equal_to(true)
    end)
  end)

  describe('equality', function()
    it('should equal sets with same elements', function()
      local a = Set{1, 2, 3}
      local b = Set{1, 2, 3}
      expect(a == b).to.be_equal_to(true)
    end)

    it('should not equal sets with different elements', function()
      local a = Set{1, 2}
      local b = Set{1, 2, 3}
      expect(a == b).to.be_equal_to(false)
    end)

    it('should not equal non-sets', function()
      local s = Set{1, 2}
      expect(s == {1, 2}).to.be_equal_to(false)
    end)
  end)

  describe('map', function()
    it('should transform elements', function()
      local s = Set{1, 2, 3}
      local result = s:map(function(x) return x * 2 end)
      expect(#result).to.be_equal_to(3)
      expect(result:contains(2)).to.be_equal_to(true)
      expect(result:contains(4)).to.be_equal_to(true)
      expect(result:contains(6)).to.be_equal_to(true)
    end)

    it('should deduplicate mapped elements', function()
      local s = Set{1, 2, 3}
      local result = s:map(function(x) return x % 2 end)
      -- Maps to {0, 1} only
      expect(#result).to.be_equal_to(2)
    end)
  end)

  describe('filter', function()
    it('should keep matching elements', function()
      local s = Set{1, 2, 3, 4, 5}
      local result = s:filter(function(x) return x > 2 end)
      expect(result:contains(3)).to.be_equal_to(true)
      expect(result:contains(4)).to.be_equal_to(true)
      expect(result:contains(5)).to.be_equal_to(true)
    end)

    it('should remove non-matching elements', function()
      local s = Set{1, 2, 3, 4, 5}
      local result = s:filter(function(x) return x > 2 end)
      expect(result:contains(1)).to.be_equal_to(false)
      expect(result:contains(2)).to.be_equal_to(false)
    end)
  end)

  describe('update', function()
    it('should add elements from other set', function()
      local a = Set{1, 2}
      local b = Set{3, 4}
      a:update(b)
      expect(#a).to.be_equal_to(4)
    end)

    it('should handle overlapping sets', function()
      local a = Set{1, 2}
      local b = Set{2, 3}
      a:update(b)
      expect(#a).to.be_equal_to(3)
    end)
  end)

  describe('clear', function()
    it('should remove all elements', function()
      local s = Set{1, 2, 3}
      s:clear()
      expect(#s).to.be_equal_to(0)
    end)
  end)

  describe('tolist', function()
    it('should convert to list', function()
      local s = Set{1, 2, 3}
      local list = s:tolist()
      expect(#list).to.be_equal_to(3)
    end)
  end)

  describe('__len', function()
    it('should return set size', function()
      local s = Set{1, 2, 3}
      expect(#s).to.be_equal_to(3)
    end)

    it('should return 0 for empty set', function()
      local s = Set{}
      expect(#s).to.be_equal_to(0)
    end)
  end)

  describe('__hash', function()
    it('should hash sets', function()
      local s = Set{1, 2, 3}
      local hash = require 'llx.hash'
      local h = hash.hash(s)
      expect(type(h)).to.be_equal_to('number')
    end)

    it('should produce same hash for equal sets', function()
      local hash = require 'llx.hash'
      local a = Set{1, 2, 3}
      local b = Set{3, 2, 1}
      expect(hash.hash(a) == hash.hash(b)).to.be_equal_to(true)
    end)
  end)

  describe('__tostring', function()
    it('should produce string representation', function()
      local s = Set{1, 2, 3}
      local str = tostring(s)
      expect(type(str)).to.be_equal_to('string')
      expect(str:find('Set{')).to.be_equal_to(1)
    end)

    it('should include all elements', function()
      local s = Set{1, 2, 3}
      local str = tostring(s)
      expect(str:find('1')).to_not.be_nil()
      expect(str:find('2')).to_not.be_nil()
      expect(str:find('3')).to_not.be_nil()
    end)
  end)

  describe('__pairs', function()
    it('should iterate over elements', function()
      local s = Set{1, 2, 3}
      local count = 0
      for k in pairs(s) do
        count = count + 1
        expect(s:contains(k)).to.be_equal_to(true)
      end
      expect(count).to.be_equal_to(3)
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end

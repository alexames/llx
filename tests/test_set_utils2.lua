-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.set'

_ENV = unit.create_test_env(_ENV)

describe('set utilities (tier 2)', function()
  describe('update', function()
    it('should add all elements from another set', function()
      local a = llx.Set{1, 2}
      a:update(llx.Set{3, 4})
      expect(a).to.be_equal_to(llx.Set{1, 2, 3, 4})
    end)

    it('should handle overlapping elements', function()
      local a = llx.Set{1, 2, 3}
      a:update(llx.Set{2, 3, 4})
      expect(a).to.be_equal_to(llx.Set{1, 2, 3, 4})
    end)

    it('should handle empty other set', function()
      local a = llx.Set{1, 2}
      a:update(llx.Set{})
      expect(a).to.be_equal_to(llx.Set{1, 2})
    end)
  end)

  describe('clear', function()
    it('should remove all elements', function()
      local s = llx.Set{1, 2, 3}
      s:clear()
      expect(s:len()).to.be_equal_to(0)
    end)

    it('should be idempotent on empty set', function()
      local s = llx.Set{}
      s:clear()
      expect(s:len()).to.be_equal_to(0)
    end)
  end)

  describe('map', function()
    it('should apply a function to each element', function()
      local s = llx.Set{1, 2, 3}
      local result = s:map(function(x) return x * 10 end)
      expect(result).to.be_equal_to(llx.Set{10, 20, 30})
    end)

    it('should not modify the original set', function()
      local s = llx.Set{1, 2}
      s:map(function(x) return x * 10 end)
      expect(s).to.be_equal_to(llx.Set{1, 2})
    end)

    it('should handle collisions (multiple elements mapping to same value)', function()
      local s = llx.Set{1, 2, 3}
      local result = s:map(function() return 'x' end)
      expect(result:len()).to.be_equal_to(1)
    end)
  end)

  describe('filter', function()
    it('should keep only elements matching the predicate', function()
      local s = llx.Set{1, 2, 3, 4, 5}
      local result = s:filter(function(x) return x > 3 end)
      expect(result).to.be_equal_to(llx.Set{4, 5})
    end)

    it('should return empty set when nothing matches', function()
      local s = llx.Set{1, 2, 3}
      local result = s:filter(function(x) return x > 10 end)
      expect(result:len()).to.be_equal_to(0)
    end)

    it('should not modify the original set', function()
      local s = llx.Set{1, 2, 3}
      s:filter(function(x) return x > 1 end)
      expect(s:len()).to.be_equal_to(3)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

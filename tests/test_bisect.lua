local unit = require 'llx.unit'
local llx = require 'llx'
local bisect_module = require 'llx.bisect'

local bisect_left = bisect_module.bisect_left
local bisect_right = bisect_module.bisect_right
local insort_left = bisect_module.insort_left
local insort_right = bisect_module.insort_right

_ENV = unit.create_test_env(_ENV)

describe('bisect', function()
  describe('bisect_left', function()
    it('should find insertion point in middle', function()
      local a = {1, 3, 5, 7}
      expect(bisect_left(a, 4)).to.be_equal_to(3)
    end)

    it('should return leftmost index for duplicates', function()
      local a = {1, 2, 2, 2, 3}
      expect(bisect_left(a, 2)).to.be_equal_to(2)
    end)

    it('should handle smaller-than-all', function()
      local a = {2, 4, 6}
      expect(bisect_left(a, 1)).to.be_equal_to(1)
    end)

    it('should handle greater-than-all', function()
      local a = {2, 4, 6}
      expect(bisect_left(a, 10)).to.be_equal_to(4)
    end)

    it('should handle empty sequence', function()
      expect(bisect_left({}, 5)).to.be_equal_to(1)
    end)

    it('should respect lo bound', function()
      local a = {1, 3, 5, 7}
      expect(bisect_left(a, 4, 3)).to.be_equal_to(3)
      expect(bisect_left(a, 0, 3)).to.be_equal_to(3)
    end)

    it('should respect hi bound', function()
      local a = {1, 3, 5, 7}
      expect(bisect_left(a, 6, 1, 3)).to.be_equal_to(3)
    end)

    it('should support a key function', function()
      local items = {{age=10}, {age=20}, {age=30}}
      local key = function(x) return x.age end
      expect(bisect_left(items, {age=15}, nil, nil, key)).to.be_equal_to(2)
    end)
  end)

  describe('bisect_right', function()
    it('should find insertion point in middle', function()
      local a = {1, 3, 5, 7}
      expect(bisect_right(a, 4)).to.be_equal_to(3)
    end)

    it('should return rightmost index for duplicates', function()
      local a = {1, 2, 2, 2, 3}
      expect(bisect_right(a, 2)).to.be_equal_to(5)
    end)

    it('should differ from bisect_left only on existing elements', function()
      local a = {1, 3, 5, 7}
      expect(bisect_right(a, 4)).to.be_equal_to(bisect_left(a, 4))
      -- For an existing element, right is one past left.
      expect(bisect_right(a, 5) - bisect_left(a, 5)).to.be_equal_to(1)
    end)

    it('should support a key function', function()
      local items = {{age=10}, {age=20}, {age=20}, {age=30}}
      local key = function(x) return x.age end
      expect(bisect_right(items, {age=20}, nil, nil, key)).to.be_equal_to(4)
    end)
  end)

  describe('bisect (alias for bisect_right)', function()
    it('should match bisect_right', function()
      local a = {1, 2, 2, 3}
      expect(bisect_module.bisect(a, 2)).to.be_equal_to(bisect_right(a, 2))
    end)
  end)

  describe('insort_left and insort_right', function()
    it('insort_left should insert at leftmost position', function()
      local a = {1, 2, 2, 3}
      local i = insort_left(a, 2)
      expect(i).to.be_equal_to(2)
      expect(a[2]).to.be_equal_to(2)
      expect(#a).to.be_equal_to(5)
    end)

    it('insort_right should insert at rightmost position', function()
      local a = {1, 2, 2, 3}
      local i = insort_right(a, 2)
      expect(i).to.be_equal_to(4)
      expect(#a).to.be_equal_to(5)
    end)

    it('should keep the sequence sorted', function()
      local a = {}
      math.randomseed(42)
      for _ = 1, 50 do
        insort_right(a, math.random(100))
      end
      for i = 2, #a do
        expect(a[i] >= a[i-1]).to.be_true()
      end
    end)

    it('should respect lo and hi bounds in insort', function()
      local a = {1, 3, 5, 7, 9}
      -- Constrain insort to [1, 3] so we only consider {1, 3, 5}.
      local i = insort_right(a, 4, 1, 4)
      -- 4 fits between 3 (index 2) and 5 (index 3); rightmost
      -- among elements <= 4 is index 3.
      expect(i).to.be_equal_to(3)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

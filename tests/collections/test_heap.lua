local unit = require 'llx.unit'
local llx = require 'llx'
local heap_module = require 'llx.collections.heap'
local Heap = heap_module.Heap
local nlargest = heap_module.nlargest
local nsmallest = heap_module.nsmallest

_ENV = unit.create_test_env(_ENV)

describe('Heap', function()
  describe('construction', function()
    it('should create an empty min-heap', function()
      local h = Heap()
      expect(#h).to.be_equal_to(0)
      expect(h:is_empty()).to.be_true()
    end)

    it('should heapify an initial list', function()
      local h = Heap{5, 3, 1, 4, 2}
      expect(#h).to.be_equal_to(5)
      expect(h:peek()).to.be_equal_to(1)
    end)

    it('should accept a custom comparator (max-heap)', function()
      local h = Heap{less = function(a, b) return a > b end}
      h:push(1)
      h:push(5)
      h:push(3)
      expect(h:peek()).to.be_equal_to(5)
    end)

    it('should heapify with a custom comparator', function()
      local h = Heap{
        1, 5, 3, 4, 2,
        less = function(a, b) return a > b end,
      }
      expect(h:peek()).to.be_equal_to(5)
    end)
  end)

  describe('push and pop', function()
    it('should pop in ascending order from a min-heap', function()
      local h = Heap()
      for _, v in ipairs({5, 1, 4, 2, 3}) do h:push(v) end
      local sorted = {}
      while not h:is_empty() do
        sorted[#sorted + 1] = h:pop()
      end
      expect(table.concat(sorted, ',')).to.be_equal_to('1,2,3,4,5')
    end)

    it('should pop in descending order from a max-heap', function()
      local h = Heap{less = function(a, b) return a > b end}
      for _, v in ipairs({5, 1, 4, 2, 3}) do h:push(v) end
      local sorted = {}
      while not h:is_empty() do
        sorted[#sorted + 1] = h:pop()
      end
      expect(table.concat(sorted, ',')).to.be_equal_to('5,4,3,2,1')
    end)

    it('should error on pop from empty heap', function()
      local h = Heap()
      expect(function() h:pop() end).to.throw()
    end)

    it('should peek without removing', function()
      local h = Heap{3, 1, 2}
      expect(h:peek()).to.be_equal_to(1)
      expect(#h).to.be_equal_to(3)
    end)

    it('should return nil from peek on empty heap', function()
      local h = Heap()
      expect(h:peek()).to.be_nil()
    end)

    it('should preserve heap invariant after many push/pop', function()
      local h = Heap()
      math.randomseed(42)
      for _ = 1, 100 do h:push(math.random(1000)) end
      local prev = h:pop()
      while not h:is_empty() do
        local v = h:pop()
        expect(v >= prev).to.be_true()
        prev = v
      end
    end)
  end)

  describe('top_n', function()
    it('should return up to n top items without mutating', function()
      local h = Heap{5, 1, 4, 2, 3}
      local top3 = h:top_n(3)
      expect(top3[1]).to.be_equal_to(1)
      expect(top3[2]).to.be_equal_to(2)
      expect(top3[3]).to.be_equal_to(3)
      expect(#h).to.be_equal_to(5)
    end)

    it('should clamp n to length', function()
      local h = Heap{2, 1}
      local top10 = h:top_n(10)
      expect(#top10).to.be_equal_to(2)
    end)
  end)

  describe('clear', function()
    it('should empty the heap', function()
      local h = Heap{1, 2, 3}
      h:clear()
      expect(h:is_empty()).to.be_true()
    end)
  end)

  describe('nlargest and nsmallest module functions', function()
    it('should return n largest in descending order', function()
      local result = nlargest({3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5}, 3)
      expect(result[1]).to.be_equal_to(9)
      expect(result[2]).to.be_equal_to(6)
      expect(result[3]).to.be_equal_to(5)
    end)

    it('should return n smallest in ascending order', function()
      local result = nsmallest({3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5}, 3)
      expect(result[1]).to.be_equal_to(1)
      expect(result[2]).to.be_equal_to(1)
      expect(result[3]).to.be_equal_to(2)
    end)

    it('should clamp n to sequence length', function()
      expect(#nlargest({1, 2}, 10)).to.be_equal_to(2)
      expect(#nsmallest({1, 2}, 10)).to.be_equal_to(2)
    end)

    it('should return empty for n <= 0', function()
      expect(#nlargest({1, 2, 3}, 0)).to.be_equal_to(0)
      expect(#nsmallest({1, 2, 3}, -1)).to.be_equal_to(0)
    end)
  end)

  describe('__eq, __tostring', function()
    it('should compare equal as multisets under same ordering', function()
      local a = Heap{1, 2, 3}
      local b = Heap{3, 2, 1}
      expect(a == b).to.be_true()
    end)

    it('should compare unequal for different contents', function()
      local a = Heap{1, 2, 3}
      local b = Heap{1, 2, 4}
      expect(a == b).to.be_false()
    end)

    it('should produce a Heap{...} tostring', function()
      local h = Heap{}
      h:push(1)
      expect(tostring(h)).to.be_equal_to('Heap{1}')
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end

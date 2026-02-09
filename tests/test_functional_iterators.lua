-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.operators'
require 'llx.functional'
require 'llx.types.list'
require 'llx.types.table'
require 'llx.types.string'

_ENV = unit.create_test_env(_ENV)

describe('functional iterators', function()
  describe('sliding_window', function()
    it('should return overlapping windows of the given width', function()
      local result = llx.List{}
      for i, a, b, c in llx.functional.sliding_window(llx.List{1, 2, 3, 4, 5}, 3) do
        result:insert(llx.List{a, b, c})
      end
      expect(result).to.be_equal_to(llx.List{
        llx.List{1, 2, 3},
        llx.List{2, 3, 4},
        llx.List{3, 4, 5},
      })
    end)

    it('should return single-element windows for width 1', function()
      local result = llx.List{}
      for i, v in llx.functional.sliding_window(llx.List{10, 20, 30}, 1) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{10, 20, 30})
    end)

    it('should return nothing when sequence is shorter than window', function()
      local result = llx.List{}
      for i, a, b, c in llx.functional.sliding_window(llx.List{1, 2}, 3) do
        result:insert(llx.List{a, b, c})
      end
      expect(#result).to.be_equal_to(0)
    end)

    it('should return one window when sequence length equals window size', function()
      local result = llx.List{}
      for i, a, b in llx.functional.sliding_window(llx.List{1, 2}, 2) do
        result:insert(llx.List{a, b})
      end
      expect(result).to.be_equal_to(llx.List{llx.List{1, 2}})
    end)
  end)

  describe('interleave', function()
    it('should alternate elements from multiple sequences', function()
      local result = llx.List{}
      for i, v in llx.functional.interleave(
        llx.List{1, 2, 3},
        llx.List{'a', 'b', 'c'}
      ) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 'a', 2, 'b', 3, 'c'})
    end)

    it('should stop when the shortest sequence is exhausted', function()
      local result = llx.List{}
      for i, v in llx.functional.interleave(
        llx.List{1, 2, 3},
        llx.List{'a', 'b'}
      ) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 'a', 2, 'b'})
    end)

    it('should handle three sequences', function()
      local result = llx.List{}
      for i, v in llx.functional.interleave(
        llx.List{1, 2},
        llx.List{'a', 'b'},
        llx.List{'x', 'y'}
      ) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 'a', 'x', 2, 'b', 'y'})
    end)

    it('should handle a single sequence', function()
      local result = llx.List{}
      for i, v in llx.functional.interleave(llx.List{1, 2, 3}) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('unzip', function()
    it('should transpose pairs into two lists', function()
      local a, b = llx.functional.unzip(llx.List{{1, 'a'}, {2, 'b'}, {3, 'c'}})
      expect(a).to.be_equal_to(llx.List{1, 2, 3})
      expect(b).to.be_equal_to(llx.List{'a', 'b', 'c'})
    end)

    it('should transpose triples into three lists', function()
      local a, b, c = llx.functional.unzip(llx.List{{1, 'a', true}, {2, 'b', false}})
      expect(a).to.be_equal_to(llx.List{1, 2})
      expect(b).to.be_equal_to(llx.List{'a', 'b'})
      expect(c).to.be_equal_to(llx.List{true, false})
    end)

    it('should return empty lists for empty input', function()
      local results = {llx.functional.unzip(llx.List{})}
      expect(#results).to.be_equal_to(0)
    end)

    it('should handle single-element tuples', function()
      local a = llx.functional.unzip(llx.List{{10}, {20}, {30}})
      expect(a).to.be_equal_to(llx.List{10, 20, 30})
    end)
  end)

  describe('combinations_with_replacement', function()
    it('should generate combinations allowing repeated elements', function()
      local result = llx.List{}
      for i, a, b in llx.functional.combinations_with_replacement(
        llx.List{'a', 'b', 'c'}, 2
      ) do
        result:insert(llx.List{a, b})
      end
      expect(result).to.be_equal_to(llx.List{
        llx.List{'a', 'a'},
        llx.List{'a', 'b'},
        llx.List{'a', 'c'},
        llx.List{'b', 'b'},
        llx.List{'b', 'c'},
        llx.List{'c', 'c'},
      })
    end)

    it('should handle r=1 as identity', function()
      local result = llx.List{}
      for i, v in llx.functional.combinations_with_replacement(
        llx.List{1, 2, 3}, 1
      ) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)

    it('should handle r equal to sequence length', function()
      local result = llx.List{}
      for i, a, b in llx.functional.combinations_with_replacement(
        llx.List{1, 2}, 2
      ) do
        result:insert(llx.List{a, b})
      end
      expect(result).to.be_equal_to(llx.List{
        llx.List{1, 1},
        llx.List{1, 2},
        llx.List{2, 2},
      })
    end)

    it('should handle r greater than sequence length', function()
      local result = llx.List{}
      for i, a, b, c in llx.functional.combinations_with_replacement(
        llx.List{1, 2}, 3
      ) do
        result:insert(llx.List{a, b, c})
      end
      expect(result).to.be_equal_to(llx.List{
        llx.List{1, 1, 1},
        llx.List{1, 1, 2},
        llx.List{1, 2, 2},
        llx.List{2, 2, 2},
      })
    end)
  end)

  describe('compact', function()
    it('should remove nil values from a sequence', function()
      local result = llx.List{}
      for _, v in llx.functional.compact(llx.List{1, nil, 2, nil, 3}) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)

    it('should remove false values', function()
      local result = llx.List{}
      for _, v in llx.functional.compact(llx.List{false, 0, '', true}) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{0, '', true})
    end)
  end)

  describe('shuffle', function()
    it('should return a List with the same elements', function()
      local input = llx.List{1, 2, 3, 4, 5}
      local result = llx.functional.shuffle(input)
      expect(#result).to.be_equal_to(5)
      local sorted_result = result:sort()
      expect(sorted_result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)

    it('should not modify the original list', function()
      local input = llx.List{1, 2, 3}
      llx.functional.shuffle(input)
      expect(input).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('sample', function()
    it('should return n elements from the sequence', function()
      local input = llx.List{1, 2, 3, 4, 5}
      local result = llx.functional.sample(input, 3)
      expect(#result).to.be_equal_to(3)
    end)

    it('should return all elements when n equals length', function()
      local input = llx.List{1, 2, 3}
      local result = llx.functional.sample(input, 3)
      expect(#result).to.be_equal_to(3)
    end)

    it('should return elements from the original sequence', function()
      local input = llx.List{10, 20, 30, 40, 50}
      local result = llx.functional.sample(input, 2)
      for _, v in result do
        local found = false
        for _, u in input do
          if u == v then found = true; break end
        end
        expect(found).to.be_true()
      end
    end)
  end)

  describe('sorted', function()
    it('should return a sorted List from an iterator', function()
      local result = llx.functional.sorted(llx.List{3, 1, 4, 1, 5})
      expect(result).to.be_equal_to(llx.List{1, 1, 3, 4, 5})
    end)

    it('should accept a custom comparator', function()
      local result = llx.functional.sorted(llx.List{3, 1, 4}, function(a, b) return a > b end)
      expect(result).to.be_equal_to(llx.List{4, 3, 1})
    end)

    it('should not modify the input', function()
      local input = llx.List{3, 1, 2}
      llx.functional.sorted(input)
      expect(input[1]).to.be_equal_to(3)
    end)
  end)

  describe('iterate', function()
    it('should generate a sequence from repeated application', function()
      local result = llx.List{}
      local iter = llx.functional.iterate(function(x) return x * 2 end, 1)
      for i = 1, 5 do
        local _, v = iter()
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 4, 8, 16})
    end)
  end)

  describe('sort_by', function()
    it('should sort by a key function', function()
      local input = llx.List{{name='Charlie'}, {name='Alice'}, {name='Bob'}}
      local result = llx.functional.sort_by(input, function(x) return x.name end)
      expect(result[1].name).to.be_equal_to('Alice')
      expect(result[2].name).to.be_equal_to('Bob')
      expect(result[3].name).to.be_equal_to('Charlie')
    end)

    it('should not modify the original list', function()
      local input = llx.List{3, 1, 2}
      llx.functional.sort_by(input, function(x) return x end)
      expect(input[1]).to.be_equal_to(3)
    end)
  end)

  describe('min_by', function()
    it('should return the element with the minimum key', function()
      local input = llx.List{{val=3}, {val=1}, {val=2}}
      local result = llx.functional.min_by(input, function(x) return x.val end)
      expect(result.val).to.be_equal_to(1)
    end)
  end)

  describe('max_by', function()
    it('should return the element with the maximum key', function()
      local input = llx.List{{val=3}, {val=1}, {val=2}}
      local result = llx.functional.max_by(input, function(x) return x.val end)
      expect(result.val).to.be_equal_to(3)
    end)
  end)

  describe('flatten_deep', function()
    it('should flatten nested lists recursively', function()
      local result = llx.functional.flatten_deep(llx.List{1, llx.List{2, llx.List{3, 4}}, 5})
      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)

    it('should flatten to a specific depth', function()
      local result = llx.functional.flatten_deep(
        llx.List{1, llx.List{2, llx.List{3, llx.List{4}}}}, 1)
      expect(result).to.be_equal_to(llx.List{1, 2, llx.List{3, llx.List{4}}})
    end)

    it('should return a flat list unchanged', function()
      local result = llx.functional.flatten_deep(llx.List{1, 2, 3})
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('unfold', function()
    it('should generate a sequence from a seed', function()
      -- Generate countdown: 5, 4, 3, 2, 1
      local result = llx.List{}
      local i = 0
      for _, v in llx.functional.unfold(function(s)
        if s <= 0 then return nil end
        return s, s - 1
      end, 5) do
        i = i + 1
        result:insert(v)
        if i > 10 then break end
      end
      expect(result).to.be_equal_to(llx.List{5, 4, 3, 2, 1})
    end)

    it('should return empty for immediate nil', function()
      local result = llx.List{}
      for _, v in llx.functional.unfold(function() return nil end, 0) do
        result:insert(v)
      end
      expect(#result).to.be_equal_to(0)
    end)
  end)

  describe('peekable', function()
    it('should allow peeking without consuming', function()
      local iter = llx.functional.peekable(llx.List{10, 20, 30})
      expect(iter:peek()).to.be_equal_to(10)
      expect(iter:peek()).to.be_equal_to(10)
      local _, v = iter()
      expect(v).to.be_equal_to(10)
      expect(iter:peek()).to.be_equal_to(20)
    end)

    it('should return nil when exhausted', function()
      local iter = llx.functional.peekable(llx.List{1})
      iter()
      expect(iter:peek()).to.be_equal_to(nil)
    end)

    it('should work in a for loop', function()
      local iter = llx.functional.peekable(llx.List{1, 2, 3})
      local result = llx.List{}
      while iter:peek() ~= nil do
        local _, v = iter()
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('split_when', function()
    it('should split when predicate is true', function()
      local result = llx.functional.split_when(
        llx.List{1, 2, 5, 6, 3, 4},
        function(x) return x > 4 end
      )
      expect(#result).to.be_equal_to(3)
      expect(result[1]).to.be_equal_to(llx.List{1, 2})
      expect(result[2]).to.be_equal_to(llx.List{5, 6})
      expect(result[3]).to.be_equal_to(llx.List{3, 4})
    end)

    it('should return single group when predicate never matches', function()
      local result = llx.functional.split_when(
        llx.List{1, 2, 3},
        function() return false end
      )
      expect(#result).to.be_equal_to(1)
      expect(result[1]).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('unique_justseen', function()
    it('should remove consecutive duplicates', function()
      local result = llx.functional.unique_justseen(llx.List{1, 1, 2, 2, 3, 1, 1})
      expect(result).to.be_equal_to(llx.List{1, 2, 3, 1})
    end)

    it('should handle no duplicates', function()
      local result = llx.functional.unique_justseen(llx.List{1, 2, 3})
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)

    it('should support a key function', function()
      local result = llx.functional.unique_justseen(
        llx.List{'a', 'A', 'b', 'B', 'a'},
        string.lower
      )
      expect(result).to.be_equal_to(llx.List{'a', 'b', 'a'})
    end)
  end)

  describe('take_nth', function()
    it('should yield every nth element', function()
      local result = llx.List{}
      for _, v in llx.functional.take_nth(llx.List{1, 2, 3, 4, 5, 6}, 2) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 3, 5})
    end)

    it('should yield all elements when n=1', function()
      local result = llx.List{}
      for _, v in llx.functional.take_nth(llx.List{1, 2, 3}, 1) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('reduce_right', function()
    it('should fold from the right', function()
      local result = llx.functional.reduce_right(
        llx.List{1, 2, 3, 4},
        function(acc, v) return acc - v end,
        0
      )
      -- 0 - 4 = -4, -4 - 3 = -7, -7 - 2 = -9, -9 - 1 = -10
      expect(result).to.be_equal_to(-10)
    end)

    it('should work with string concatenation', function()
      local result = llx.functional.reduce_right(
        llx.List{'a', 'b', 'c'},
        function(acc, v) return acc .. v end,
        ''
      )
      expect(result).to.be_equal_to('cba')
    end)
  end)

  describe('zip_with', function()
    it('should zip and apply a function', function()
      local result = llx.functional.zip_with(
        function(a, b) return a + b end,
        llx.List{1, 2, 3},
        llx.List{10, 20, 30}
      )
      expect(result).to.be_equal_to(llx.List{11, 22, 33})
    end)

    it('should stop at shortest', function()
      local result = llx.functional.zip_with(
        function(a, b) return a * b end,
        llx.List{1, 2, 3, 4},
        llx.List{10, 20}
      )
      expect(result).to.be_equal_to(llx.List{10, 40})
    end)
  end)

  describe('scan', function()
    it('should produce running accumulations', function()
      local result = llx.List{}
      for _, v in llx.functional.scan(llx.List{1, 2, 3, 4}, function(a, b) return a + b end, 0) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 3, 6, 10})
    end)

    it('should work without initial value', function()
      local result = llx.List{}
      for _, v in llx.functional.scan(llx.List{1, 2, 3}, function(a, b) return a + b end) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 3, 6})
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

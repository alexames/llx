-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.debug.trace'
require 'llx.operators'
require 'llx.types.list'
require 'llx.types.table'
require 'llx.types.string'

_ENV = unit.create_test_env(_ENV)

describe('functional', function()
  describe('range', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- range(a, b, c)
    end)
  end)

  describe('generator', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- generator(iterator, state, control, closing)
    end)
  end)

  describe('map', function()
    it('should work', function(...)
      -- TODO: Add actual test implementation
      -- map(lambda, ...)
    end)
  end)

  describe('filter', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- filter(lambda, sequence)
    end)
  end)

  describe('count', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- count(start, step)
    end)
  end)

  describe('cycle', function()
    it('should cycle through a sequence infinitely', function()
      local seq = llx.List{1, 2, 3}
      local cycled = llx.functional.cycle(seq)
      local results = {}
      for i = 1, 10 do
        local _, v = cycled()
        results[i] = v
      end
      expect(results).to.be_equal_to({1, 2, 3, 1, 2, 3, 1, 2, 3, 1})
    end)

    it('should handle empty sequence', function()
      local seq = llx.List{}
      local cycled = llx.functional.cycle(seq)
      expect(cycled()).to.be_nil()
    end)
  end)

  describe('repeat_elem', function()
    it('should repeat element specified number of times', function()
      local repeated = llx.functional.repeat_elem('a', 3)
      local results = {}
      for i = 1, 5 do
        local _, v = repeated()
        if v then
          results[i] = v
        end
      end
      expect(results).to.be_equal_to({'a', 'a', 'a'})
    end)

    it('should repeat element infinitely when times is nil', function()
      local repeated = llx.functional.repeat_elem('x')
      local results = {}
      for i = 1, 5 do
        local _, v = repeated()
        results[i] = v
      end
      expect(results).to.be_equal_to({'x', 'x', 'x', 'x', 'x'})
    end)
  end)

  describe('accumulate', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- accumulate(sequence, lambda, initial_value)
    end)
  end)

  describe('batched', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- batched(iterable, n)
    end)
  end)

  describe('chain', function()
    it('should chain multiple sequences together', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{4, 5, 6}
      local chained = llx.functional.chain(seq1, seq2)
      local results = {}
      for i, v in chained do
        results[i] = v
      end
      expect(results).to.be_equal_to({1, 2, 3, 4, 5, 6})
    end)
  end)

  describe('compress', function()
    it('should filter sequence based on selectors', function()
      local seq = llx.List{1, 2, 3, 4, 5}
      local selectors = llx.List{true, false, true, false, true}
      local compressed = llx.functional.compress(seq, selectors)
      local results = {}
      for i, v in compressed do
        results[i] = v
      end
      expect(results).to.be_equal_to({1, 3, 5})
    end)
  end)

  describe('drop_while', function()
    it('should drop elements while predicate is true', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6}
      local dropped = llx.functional.drop_while(function(x) return x < 4 end, seq)
      local results = {}
      for i, v in dropped do
        results[i] = v
      end
      expect(results).to.be_equal_to({4, 5, 6})
    end)
  end)

  describe('filterfalse', function()
    it('should filter out elements where predicate is true', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6}
      local filtered = llx.functional.filterfalse(function(x) return x % 2 == 0 end, seq)
      local results = {}
      for i, v in filtered do
        results[i] = v
      end
      expect(results).to.be_equal_to({1, 3, 5})
    end)
  end)

  describe('group_by', function()
    it('should group elements by key function', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6}
      local grouped = llx.functional.group_by(seq, function(x) return x % 2 end)
      local groups = {}
      for key, values in grouped do
        groups[key] = values
      end
      expect(groups[0]).to.contain_element(2)
      expect(groups[0]).to.contain_element(4)
      expect(groups[0]).to.contain_element(6)
      expect(groups[1]).to.contain_element(1)
      expect(groups[1]).to.contain_element(3)
      expect(groups[1]).to.contain_element(5)
    end)
  end)

  describe('slice', function()
    it('should slice sequence with start and stop', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6, 7, 8}
      local sliced = llx.functional.slice(seq, 2, 5)
      local results = {}
      for i, v in sliced do
        results[i] = v
      end
      expect(results).to.be_equal_to({2, 3, 4})
    end)

    it('should slice with step', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6, 7, 8}
      local sliced = llx.functional.slice(seq, 1, 8, 2)
      local results = {}
      for i, v in sliced do
        results[i] = v
      end
      expect(results).to.be_equal_to({1, 3, 5, 7})
    end)
  end)

  describe('pairwise', function()
    it('should return pairs of consecutive elements', function()
      local seq = llx.List{1, 2, 3, 4, 5}
      local paired = llx.functional.pairwise(seq)
      local results = {}
      for i, a, b in paired do
        results[i] = {a, b}
      end
      expect(results[1]).to.be_equal_to({1, 2})
      expect(results[2]).to.be_equal_to({2, 3})
      expect(results[3]).to.be_equal_to({3, 4})
      expect(results[4]).to.be_equal_to({4, 5})
    end)
  end)

  describe('star_map', function()
    it('should apply function to unpacked arguments', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{4, 5, 6}
      local mapped = llx.functional.star_map(function(a, b) return a + b end, seq1, seq2)
      local results = {}
      for i = 1, 3 do
        results[i] = mapped()
      end
      expect(results).to.be_equal_to({5, 7, 9})
    end)
  end)

  describe('take_while', function()
    it('should take elements while predicate is true', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6}
      local taken = llx.functional.take_while(function(x) return x < 4 end, seq)
      local results = {}
      for i, v in taken do
        results[i] = v
      end
      expect(results).to.be_equal_to({1, 2, 3})
    end)
  end)

  describe('tee', function()
    it('should create multiple independent iterators', function()
      local seq = llx.List{1, 2, 3, 4, 5}
      local it1, it2 = llx.functional.tee(seq, 2)
      local results1 = {}
      local results2 = {}
      for i = 1, 3 do
        local _, v1 = it1()
        local _, v2 = it2()
        results1[i] = v1
        results2[i] = v2
      end
      expect(results1).to.be_equal_to({1, 2, 3})
      expect(results2).to.be_equal_to({1, 2, 3})
    end)
  end)

  describe('zip_longest', function()
    it('should zip sequences with fillvalue for missing elements', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{4, 5}
      local zipped = llx.functional.zip_longest(seq1, seq2, 0)
      local results = {}
      for i, a, b in zipped do
        results[i] = {a, b}
      end
      expect(results[1]).to.be_equal_to({1, 4})
      expect(results[2]).to.be_equal_to({2, 5})
      expect(results[3]).to.be_equal_to({3, 0})
    end)
  end)

  describe('permutations', function()
    it('should generate all permutations of length r', function()
      local seq = llx.List{1, 2, 3}
      local perms = llx.functional.permutations(seq, 2)
      local results = {}
      for i, a, b in perms do
        results[i] = {a, b}
      end
      expect(#results).to.be_equal_to(6)
      expect(results[1]).to.be_equal_to({1, 2})
      expect(results[2]).to.be_equal_to({1, 3})
    end)
  end)

  describe('combinations', function()
    it('should generate all combinations of length r', function()
      local seq = llx.List{1, 2, 3}
      local combos = llx.functional.combinations(seq, 2)
      local results = {}
      for i, a, b in combos do
        results[i] = {a, b}
      end
      expect(#results).to.be_equal_to(3)
      expect(results[1]).to.be_equal_to({1, 2})
      expect(results[2]).to.be_equal_to({1, 3})
      expect(results[3]).to.be_equal_to({2, 3})
    end)
  end)

  describe('reduce', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- reduce(sequence, lambda, initial_value)
    end)
  end)

  describe('min', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- min(sequence)
    end)
  end)

  describe('max', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- max(sequence)
    end)
  end)

  describe('sum', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- sum(sequence)
    end)
  end)

  describe('product', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- product(sequence)
    end)
  end)

  describe('zip_impl', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- zip_impl(iterators, result_handler)
    end)
  end)

  describe('zip_packed', function()
    it('should work', function(...)
      -- TODO: Add actual test implementation
      -- zip_packed(...)
    end)
  end)

  describe('zip', function()
    it('should work', function(...)
      -- TODO: Add actual test implementation
      -- zip(...)
    end)
  end)

  describe('cartesian_product', function()
    it('should work', function(...)
      -- TODO: Add actual test implementation
      -- cartesian_product(...)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

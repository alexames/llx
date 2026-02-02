-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
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
    it('should generate range with single argument (end)', function()
      local results = llx.List{}
      for _, v in llx.functional.range(5) do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 2, 3, 4})
    end)

    it('should generate range with start and end', function()
      local results = llx.List{}
      for _, v in llx.functional.range(2, 6) do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{2, 3, 4, 5})
    end)

    it('should generate range with start, end, and step', function()
      local results = llx.List{}
      for _, v in llx.functional.range(1, 10, 2) do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 3, 5, 7, 9})
    end)

    it('should generate descending range with negative step', function()
      local results = llx.List{}
      for _, v in llx.functional.range(5, 0, -1) do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{5, 4, 3, 2, 1})
    end)
  end)

  describe('generator', function()
    it('should wrap an iterator into a stateless generator', function()
      local function my_iterator(_, control)
        control = (control or 0) + 1
        if control <= 3 then
          return control, control * 10
        end
        return nil
      end

      local gen = llx.functional.generator(my_iterator, nil, nil)
      local results = llx.List{}
      for _ = 1, 3 do
        local _, val = gen()
        results:insert(val)
      end
      expect(results).to.be_equal_to(llx.List{10, 20, 30})
    end)
  end)

  describe('map', function()
    it('should apply function to each element', function()
      local result = llx.functional.map(function(x) return x * 2 end, llx.functional.range(5))
      expect(result).to.be_equal_to(llx.List{2, 4, 6, 8})
    end)

    it('should work with multiple sequences', function()
      local seq1 = llx.functional.range(4)
      local seq2 = llx.functional.range(4)
      local result = llx.functional.map(function(a, b) return a + b end, seq1, seq2)
      expect(result).to.be_equal_to(llx.List{2, 4, 6})
    end)
  end)

  describe('filter', function()
    it('should filter elements based on predicate', function()
      local results = llx.List{}
      for _, v in llx.functional.filter(function(x) return x > 3 end, llx.functional.range(10)) do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{4, 5, 6, 7, 8, 9})
    end)

    it('should use nonnil as default predicate', function()
      -- Note: Can't use nil values in sequences as they stop iteration
      -- Test filter with truthy/falsy values using a custom iterator
      local seq = llx.functional.range(6)  -- 1, 2, 3, 4, 5
      local results = llx.List{}
      for _, v in llx.functional.filter(nil, seq) do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)
  end)

  describe('count', function()
    it('should count from start with default step of 1', function()
      local counter = llx.functional.count(10)
      expect(counter()).to.be_equal_to(10)
      expect(counter()).to.be_equal_to(11)
      expect(counter()).to.be_equal_to(12)
    end)

    it('should count with custom step', function()
      local counter = llx.functional.count(0, 5)
      expect(counter()).to.be_equal_to(0)
      expect(counter()).to.be_equal_to(5)
      expect(counter()).to.be_equal_to(10)
    end)

    it('should use default start of 1', function()
      local counter = llx.functional.count()
      expect(counter()).to.be_equal_to(1)
      expect(counter()).to.be_equal_to(2)
    end)
  end)

  describe('cycle', function()
    it('should cycle through a sequence infinitely', function()
      local seq = llx.List{1, 2, 3}
      local cycled = llx.functional.cycle(seq)
      local results = llx.List{}
      for _ = 1, 10 do
        local _, v = cycled()
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 2, 3, 1, 2, 3, 1, 2, 3, 1})
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
      local results = llx.List{}
      for _ = 1, 5 do
        local _, v = repeated()
        if v then
          results:insert(v)
        end
      end
      expect(results).to.be_equal_to(llx.List{'a', 'a', 'a'})
    end)

    it('should repeat element infinitely when times is nil', function()
      local repeated = llx.functional.repeat_elem('x')
      local results = llx.List{}
      for _ = 1, 5 do
        local _, v = repeated()
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{'x', 'x', 'x', 'x', 'x'})
    end)
  end)

  describe('accumulate', function()
    it('should create running sum', function()
      local result = llx.functional.accumulate(llx.functional.range(5), function(a, b) return a + b end)
      expect(result).to.be_equal_to(llx.List{1, 3, 6, 10})
    end)

    it('should work with initial value', function()
      local result = llx.functional.accumulate(llx.functional.range(4), function(a, b) return a + b end, 10)
      expect(result).to.be_equal_to(llx.List{10, 11, 13, 16})
    end)

    it('should work with multiplication', function()
      local result = llx.functional.accumulate(llx.functional.range(2, 6), function(a, b) return a * b end)
      expect(result).to.be_equal_to(llx.List{2, 6, 24, 120})
    end)
  end)

  describe('batched', function()
    it('should batch elements into groups', function()
      local results = {}
      for i, batch in llx.functional.batched(llx.functional.range(11), 3) do
        results[i] = llx.List(batch)
      end
      expect(results[1]).to.be_equal_to(llx.List{1, 2, 3})
      expect(results[2]).to.be_equal_to(llx.List{4, 5, 6})
      expect(results[3]).to.be_equal_to(llx.List{7, 8, 9})
      expect(results[4]).to.be_equal_to(llx.List{10})
    end)

    it('should error when n is less than 1', function()
      expect(function() llx.functional.batched(llx.functional.range(5), 0) end).to.throw()
    end)
  end)

  describe('chain', function()
    it('should chain multiple sequences together', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{4, 5, 6}
      local chained = llx.functional.chain(seq1, seq2)
      local results = llx.List{}
      for _, v in chained do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 2, 3, 4, 5, 6})
    end)
  end)

  describe('compress', function()
    it('should filter sequence based on selectors', function()
      local seq = llx.List{1, 2, 3, 4, 5}
      local selectors = llx.List{true, false, true, false, true}
      local compressed = llx.functional.compress(seq, selectors)
      local results = llx.List{}
      for _, v in compressed do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 3, 5})
    end)
  end)

  describe('drop_while', function()
    it('should drop elements while predicate is true', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6}
      local dropped = llx.functional.drop_while(function(x) return x < 4 end, seq)
      local results = llx.List{}
      for _, v in dropped do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{4, 5, 6})
    end)
  end)

  describe('filterfalse', function()
    it('should filter out elements where predicate is true', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6}
      local filtered = llx.functional.filterfalse(function(x) return x % 2 == 0 end, seq)
      local results = llx.List{}
      for _, v in filtered do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 3, 5})
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
      local results = llx.List{}
      for _, v in sliced do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{2, 3, 4})
    end)

    it('should slice with step', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6, 7, 8}
      local sliced = llx.functional.slice(seq, 1, 8, 2)
      local results = llx.List{}
      for _, v in sliced do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 3, 5, 7})
    end)
  end)

  describe('pairwise', function()
    it('should return pairs of consecutive elements', function()
      local seq = llx.List{1, 2, 3, 4, 5}
      local paired = llx.functional.pairwise(seq)
      local results = llx.List{}
      for _, a, b in paired do
        results:insert(llx.List{a, b})
      end
      expect(results[1]).to.be_equal_to(llx.List{1, 2})
      expect(results[2]).to.be_equal_to(llx.List{2, 3})
      expect(results[3]).to.be_equal_to(llx.List{3, 4})
      expect(results[4]).to.be_equal_to(llx.List{4, 5})
    end)
  end)

  describe('star_map', function()
    it('should apply function to unpacked arguments', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{4, 5, 6}
      local mapped = llx.functional.star_map(function(a, b) return a + b end, seq1, seq2)
      local results = llx.List{}
      for _ = 1, 3 do
        results:insert(mapped())
      end
      expect(results).to.be_equal_to(llx.List{5, 7, 9})
    end)
  end)

  describe('take_while', function()
    it('should take elements while predicate is true', function()
      local seq = llx.List{1, 2, 3, 4, 5, 6}
      local taken = llx.functional.take_while(function(x) return x < 4 end, seq)
      local results = llx.List{}
      for _, v in taken do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('tee', function()
    it('should create multiple independent iterators', function()
      local seq = llx.List{1, 2, 3, 4, 5}
      local it1, it2 = llx.functional.tee(seq, 2)
      local results1 = llx.List{}
      local results2 = llx.List{}
      for _ = 1, 3 do
        local _, v1 = it1()
        local _, v2 = it2()
        results1:insert(v1)
        results2:insert(v2)
      end
      expect(results1).to.be_equal_to(llx.List{1, 2, 3})
      expect(results2).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('zip_longest', function()
    it('should zip sequences with fillvalue for missing elements', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{4, 5}
      local zipped = llx.functional.zip_longest(seq1, seq2, 0)
      local results = llx.List{}
      local i = 0
      for a, b in zipped do
        i = i + 1
        results:insert(llx.List{a, b})
      end
      expect(results[1]).to.be_equal_to(llx.List{1, 4})
      expect(results[2]).to.be_equal_to(llx.List{2, 5})
      expect(results[3]).to.be_equal_to(llx.List{3, 0})
    end)
  end)

  describe('permutations', function()
    it('should generate all permutations of length r', function()
      local seq = llx.List{1, 2, 3}
      local perms = llx.functional.permutations(seq, 2)
      local results = llx.List{}
      for i, a, b in perms do
        results[i] = llx.List{a, b}
      end
      expect(#results).to.be_equal_to(6)
      expect(results[1]).to.be_equal_to(llx.List{1, 2})
      expect(results[2]).to.be_equal_to(llx.List{1, 3})
    end)
  end)

  describe('combinations', function()
    it('should generate all combinations of length r', function()
      local seq = llx.List{1, 2, 3}
      local combos = llx.functional.combinations(seq, 2)
      local results = llx.List{}
      for i, a, b in combos do
        results[i] = llx.List{a, b}
      end
      expect(#results).to.be_equal_to(3)
      expect(results[1]).to.be_equal_to(llx.List{1, 2})
      expect(results[2]).to.be_equal_to(llx.List{1, 3})
      expect(results[3]).to.be_equal_to(llx.List{2, 3})
    end)
  end)

  describe('reduce', function()
    it('should reduce sequence to single value', function()
      local result = llx.functional.reduce(llx.functional.range(5), function(a, b) return a + b end)
      expect(result).to.be_equal_to(10)
    end)

    it('should work with initial value', function()
      local result = llx.functional.reduce(llx.functional.range(5), function(a, b) return a + b end, 100)
      expect(result).to.be_equal_to(110)
    end)

    it('should work with string concatenation', function()
      local seq = llx.List{'a', 'b', 'c'}
      local result = llx.functional.reduce(seq, function(a, b) return a .. b end, '')
      expect(result).to.be_equal_to('abc')
    end)
  end)

  describe('min', function()
    it('should return minimum element', function()
      local result = llx.functional.min(llx.functional.range(2, 10))
      expect(result).to.be_equal_to(2)
    end)

    it('should work with unordered sequence', function()
      local result = llx.functional.min(llx.List{5, 2, 8, 1, 9})
      expect(result).to.be_equal_to(1)
    end)
  end)

  describe('max', function()
    it('should return maximum element', function()
      local result = llx.functional.max(llx.functional.range(10))
      expect(result).to.be_equal_to(9)
    end)

    it('should work with unordered sequence', function()
      local result = llx.functional.max(llx.List{5, 2, 8, 1, 9})
      expect(result).to.be_equal_to(9)
    end)
  end)

  describe('sum', function()
    it('should return sum of elements', function()
      local result = llx.functional.sum(llx.functional.range(6))
      expect(result).to.be_equal_to(15)
    end)

    it('should work with custom sequence', function()
      local result = llx.functional.sum(llx.List{10, 20, 30})
      expect(result).to.be_equal_to(60)
    end)
  end)

  describe('product', function()
    it('should return product of elements', function()
      local result = llx.functional.product(llx.functional.range(5))
      expect(result).to.be_equal_to(24)
    end)

    it('should work with custom sequence', function()
      local result = llx.functional.product(llx.List{2, 3, 4})
      expect(result).to.be_equal_to(24)
    end)
  end)

  describe('zip_impl', function()
    it('should zip iterators with custom result handler', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{4, 5, 6}
      local zipped = llx.functional.zip_impl({seq1, seq2}, function(t) return t[1] + t[2] end)
      local results = llx.List{}
      for _, v in zipped do
        results:insert(v)
      end
      expect(results).to.be_equal_to(llx.List{5, 7, 9})
    end)
  end)

  describe('zip_packed', function()
    it('should zip sequences returning packed tables', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{'a', 'b', 'c'}
      local results = llx.List{}
      for _, packed in llx.functional.zip_packed(seq1, seq2) do
        results:insert(llx.List(packed))
      end
      expect(results[1]).to.be_equal_to(llx.List{1, 'a'})
      expect(results[2]).to.be_equal_to(llx.List{2, 'b'})
      expect(results[3]).to.be_equal_to(llx.List{3, 'c'})
    end)
  end)

  describe('zip', function()
    it('should zip sequences returning unpacked values', function()
      local seq1 = llx.List{1, 2, 3}
      local seq2 = llx.List{4, 5, 6}
      local results = llx.List{}
      for _, a, b in llx.functional.zip(seq1, seq2) do
        results:insert(llx.List{a, b})
      end
      expect(results[1]).to.be_equal_to(llx.List{1, 4})
      expect(results[2]).to.be_equal_to(llx.List{2, 5})
      expect(results[3]).to.be_equal_to(llx.List{3, 6})
    end)

    it('should stop when shortest sequence ends', function()
      local seq1 = llx.List{1, 2, 3, 4, 5}
      local seq2 = llx.List{'a', 'b'}
      local results = llx.List{}
      for _, a, b in llx.functional.zip(seq1, seq2) do
        results:insert(llx.List{a, b})
      end
      expect(#results).to.be_equal_to(2)
    end)
  end)

  describe('cartesian_product', function()
    it('should generate cartesian product of sequences', function()
      local seq1 = llx.List{1, 2}
      local seq2 = llx.List{'a', 'b'}
      local results = llx.List{}
      for _, a, b in llx.functional.cartesian_product(seq1, seq2) do
        results:insert(llx.List{a, b})
      end
      expect(#results).to.be_equal_to(4)
      expect(results[1]).to.be_equal_to(llx.List{1, 'a'})
      expect(results[2]).to.be_equal_to(llx.List{1, 'b'})
      expect(results[3]).to.be_equal_to(llx.List{2, 'a'})
      expect(results[4]).to.be_equal_to(llx.List{2, 'b'})
    end)

    it('should work with three sequences', function()
      local seq1 = llx.List{1, 2}
      local seq2 = llx.List{'a'}
      local seq3 = llx.List{true, false}
      local count = 0
      for _ in llx.functional.cartesian_product(seq1, seq2, seq3) do
        count = count + 1
      end
      expect(count).to.be_equal_to(4)
    end)
  end)

  -- New functional operators tests
  describe('flatmap', function()
    it('should flatten mapped results', function()
      local function duplicate(x)
        local i = 0
        return function()
          i = i + 1
          if i <= 2 then return i, x end
          return nil
        end
      end

      local result = llx.List(llx.functional.flatmap(duplicate, llx.functional.range(4)))
      expect(result).to.be_equal_to(llx.List{1, 1, 2, 2, 3, 3})
    end)
  end)

  describe('partition', function()
    it('should split sequence by predicate', function()
      local function is_even(x) return x % 2 == 0 end
      local evens, odds = llx.functional.partition(is_even, llx.functional.range(7))

      expect(evens).to.be_equal_to(llx.List{2, 4, 6})
      expect(odds).to.be_equal_to(llx.List{1, 3, 5})
    end)

    it('should use nonnil as default predicate', function()
      local data = llx.functional.range(6)
      local truthy, falsy = llx.functional.partition(nil, data)

      expect(#truthy).to.be_equal_to(5)
      expect(#falsy).to.be_equal_to(0)
    end)
  end)

  describe('find', function()
    it('should return first matching element', function()
      local function is_even(x) return x % 2 == 0 end
      local result = llx.functional.find(is_even, llx.functional.range(10))

      expect(result).to.be_equal_to(2)
    end)

    it('should return nil if not found', function()
      local function is_negative(x) return x < 0 end
      local result = llx.functional.find(is_negative, llx.functional.range(10))

      expect(result).to.be_nil()
    end)
  end)

  describe('find_index', function()
    it('should return index of first matching element', function()
      local function is_even(x) return x % 2 == 0 end
      local result = llx.functional.find_index(is_even, llx.functional.range(10))

      expect(result).to.be_equal_to(2)
    end)

    it('should return nil if not found', function()
      local function is_negative(x) return x < 0 end
      local result = llx.functional.find_index(is_negative, llx.functional.range(10))

      expect(result).to.be_nil()
    end)
  end)

  describe('distinct', function()
    it('should remove duplicates', function()
      local list = llx.List{1, 2, 2, 3, 1, 4, 3, 5}

      local result = llx.functional.distinct(list)
      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)

    it('should use key_func for uniqueness', function()
      local list = llx.List{
        {id=1, name='Alice'},
        {id=2, name='Bob'},
        {id=1, name='Alice2'}
      }

      local function get_id(item) return item.id end
      local result = llx.functional.distinct(list, get_id)

      expect(#result).to.be_equal_to(2)
      expect(result[1].name).to.be_equal_to('Alice')
      expect(result[2].name).to.be_equal_to('Bob')
    end)
  end)

  describe('unique', function()
    it('should be an alias for distinct', function()
      expect(llx.functional.unique).to.be_equal_to(llx.functional.distinct)
    end)
  end)

  describe('flatten', function()
    it('should flatten nested sequences', function()
      local nested = llx.List{
        llx.List{1, 2},
        llx.List{3, 4},
        llx.List{5}
      }

      local result = llx.List(llx.functional.flatten(nested))
      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)
  end)

  describe('enumerate', function()
    it('should return index and value pairs', function()
      local list = llx.List{'a', 'b', 'c'}

      local indices = llx.List{}
      local values = llx.List{}

      for _, idx, val in llx.functional.enumerate(list) do
        indices:insert(idx)
        values:insert(val)
      end

      expect(indices).to.be_equal_to(llx.List{1, 2, 3})
      expect(values).to.be_equal_to(llx.List{'a', 'b', 'c'})
    end)

    it('should support custom start index', function()
      local list = llx.List{'a', 'b', 'c'}

      local indices = llx.List{}

      for _, idx in llx.functional.enumerate(list, 10) do
        indices:insert(idx)
      end

      expect(indices).to.be_equal_to(llx.List{10, 11, 12})
    end)
  end)

  describe('memoize', function()
    it('should cache function results', function()
      local call_count = 0
      local function expensive(x)
        call_count = call_count + 1
        return x * 2
      end

      local memoized = llx.functional.memoize(expensive)

      expect(memoized(5)).to.be_equal_to(10)
      expect(call_count).to.be_equal_to(1)

      expect(memoized(5)).to.be_equal_to(10)
      expect(call_count).to.be_equal_to(1)

      expect(memoized(10)).to.be_equal_to(20)
      expect(call_count).to.be_equal_to(2)
    end)

    it('should support custom key function', function()
      local call_count = 0
      local function expensive(x, y)
        call_count = call_count + 1
        return x + y
      end

      local function key_func(x, y)
        return x .. ',' .. y
      end

      local memoized = llx.functional.memoize(expensive, key_func)

      expect(memoized(1, 2)).to.be_equal_to(3)
      expect(call_count).to.be_equal_to(1)

      expect(memoized(1, 2)).to.be_equal_to(3)
      expect(call_count).to.be_equal_to(1)
    end)
  end)

  describe('any', function()
    it('should return true if any element matches', function()
      local function is_even(x) return x % 2 == 0 end
      local result = llx.functional.any(is_even, llx.functional.range(5))

      expect(result).to.be_true()
    end)

    it('should return false if no elements match', function()
      local function is_negative(x) return x < 0 end
      local result = llx.functional.any(is_negative, llx.functional.range(5))

      expect(result).to.be_false()
    end)
  end)

  describe('all', function()
    it('should return true if all elements match', function()
      local function is_positive(x) return x > 0 end
      local result = llx.functional.all(is_positive, llx.functional.range(5))

      expect(result).to.be_true()
    end)

    it('should return false if any element does not match', function()
      local function is_even(x) return x % 2 == 0 end
      local result = llx.functional.all(is_even, llx.functional.range(5))

      expect(result).to.be_false()
    end)
  end)

  describe('none', function()
    it('should return true if no elements match', function()
      local function is_negative(x) return x < 0 end
      local result = llx.functional.none(is_negative, llx.functional.range(5))

      expect(result).to.be_true()
    end)

    it('should return false if any element matches', function()
      local function is_even(x) return x % 2 == 0 end
      local result = llx.functional.none(is_even, llx.functional.range(5))

      expect(result).to.be_false()
    end)
  end)

  describe('tap', function()
    it('should call function and pass through values', function()
      local side_effects = llx.List{}

      local function record(x)
        side_effects:insert(x)
      end

      local result = llx.List(llx.functional.tap(record, llx.functional.range(4)))

      expect(result).to.be_equal_to(llx.List{1, 2, 3})
      expect(side_effects).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

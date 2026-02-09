-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>
-- Tests for new List methods

local llx = require 'llx'
local unit = require 'llx.unit.test_api'

local describe = unit.describe
local it = unit.it
local expect = unit.expect

describe('List Methods', function()

  describe('map', function()
    it('should apply function to each element', function()
      local list = llx.List{1, 2, 3, 4}
      local result = list:map(function(x) return x * 2 end)

      expect(result).to.be_equal_to(llx.List{2, 4, 6, 8})
    end)

    it('should pass index to function', function()
      local list = llx.List{'a', 'b', 'c'}
      local result = list:map(function(v, i) return i end)

      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)

    it('should work on empty list', function()
      local list = llx.List{}
      local result = list:map(function(x) return x * 2 end)

      expect(result).to.be_equal_to(llx.List{})
    end)
  end)

  describe('filter', function()
    it('should keep only matching elements', function()
      local list = llx.List{1, 2, 3, 4, 5, 6}
      local result = list:filter(function(x) return x % 2 == 0 end)

      expect(result).to.be_equal_to(llx.List{2, 4, 6})
    end)

    it('should pass index to predicate', function()
      local list = llx.List{10, 20, 30, 40}
      local result = list:filter(function(v, i) return i > 2 end)

      expect(result).to.be_equal_to(llx.List{30, 40})
    end)

    it('should return empty list when nothing matches', function()
      local list = llx.List{1, 3, 5}
      local result = list:filter(function(x) return x % 2 == 0 end)

      expect(result).to.be_equal_to(llx.List{})
    end)
  end)

  describe('reduce', function()
    it('should reduce to single value with initial', function()
      local list = llx.List{1, 2, 3, 4}
      local result = list:reduce(function(acc, x) return acc + x end, 0)

      expect(result).to.be_equal_to(10)
    end)

    it('should reduce without initial value', function()
      local list = llx.List{1, 2, 3, 4}
      local result = list:reduce(function(acc, x) return acc * x end)

      expect(result).to.be_equal_to(24)
    end)

    it('should throw error on empty list without initial', function()
      local list = llx.List{}

      expect(function()
        list:reduce(function(acc, x) return acc + x end)
      end).to.throw('Reduce of empty list with no initial value')
    end)

    it('should pass index to reducer', function()
      local list = llx.List{1, 2, 3}
      local result = list:reduce(function(acc, v, i) return acc + i end, 0)

      expect(result).to.be_equal_to(6)
    end)
  end)

  describe('find', function()
    it('should return first matching element', function()
      local list = llx.List{1, 2, 3, 4, 5}
      local result = list:find(function(x) return x > 3 end)

      expect(result).to.be_equal_to(4)
    end)

    it('should return nil when no match', function()
      local list = llx.List{1, 2, 3}
      local result = list:find(function(x) return x > 10 end)

      expect(result).to.be_nil()
    end)
  end)

  describe('find_index', function()
    it('should return index of first match', function()
      local list = llx.List{1, 2, 3, 4, 5}
      local result = list:find_index(function(x) return x > 3 end)

      expect(result).to.be_equal_to(4)
    end)

    it('should return nil when no match', function()
      local list = llx.List{1, 2, 3}
      local result = list:find_index(function(x) return x > 10 end)

      expect(result).to.be_nil()
    end)
  end)

  describe('sort', function()
    it('should sort numbers in ascending order', function()
      local list = llx.List{3, 1, 4, 1, 5, 9, 2, 6}
      local result = list:sort()

      expect(result).to.be_equal_to(llx.List{1, 1, 2, 3, 4, 5, 6, 9})
      expect(list).to.be_equal_to(llx.List{3, 1, 4, 1, 5, 9, 2, 6})
    end)

    it('should sort in place when requested', function()
      local list = llx.List{3, 1, 4, 1, 5}
      local result = list:sort(nil, true)

      expect(result).to.be_equal_to(llx.List{1, 1, 3, 4, 5})
      expect(list).to.be_equal_to(llx.List{1, 1, 3, 4, 5})
    end)

    it('should sort with custom comparator', function()
      local list = llx.List{1, 2, 3, 4, 5}
      local result = list:sort(function(a, b) return a > b end)

      expect(result).to.be_equal_to(llx.List{5, 4, 3, 2, 1})
    end)
  end)

  describe('group_by', function()
    it('should group elements by key', function()
      local list = llx.List{
        {type='fruit', name='apple'},
        {type='veggie', name='carrot'},
        {type='fruit', name='banana'}
      }
      local groups, order = list:group_by(function(item) return item.type end)

      expect(#groups['fruit']).to.be_equal_to(2)
      expect(#groups['veggie']).to.be_equal_to(1)
      expect(groups['fruit'][1].name).to.be_equal_to('apple')
      expect(groups['fruit'][2].name).to.be_equal_to('banana')
    end)

    it('should return group order', function()
      local list = llx.List{1, 2, 3, 4, 5}
      local groups, order = list:group_by(function(x) return x % 2 == 0 and 'even' or 'odd' end)

      expect(order[1]).to.be_equal_to('odd')
      expect(order[2]).to.be_equal_to('even')
    end)
  end)

  describe('zip', function()
    it('should combine two lists into pairs', function()
      local list1 = llx.List{1, 2, 3}
      local list2 = llx.List{'a', 'b', 'c'}
      local result = list1:zip(list2)

      expect(#result).to.be_equal_to(3)
      expect(result[1][1]).to.be_equal_to(1)
      expect(result[1][2]).to.be_equal_to('a')
      expect(result[3][1]).to.be_equal_to(3)
      expect(result[3][2]).to.be_equal_to('c')
    end)

    it('should stop at shorter list', function()
      local list1 = llx.List{1, 2, 3, 4, 5}
      local list2 = llx.List{'a', 'b'}
      local result = list1:zip(list2)

      expect(#result).to.be_equal_to(2)
    end)
  end)

  describe('flatten', function()
    it('should flatten list of lists', function()
      local list = llx.List{
        llx.List{1, 2},
        llx.List{3, 4},
        llx.List{5}
      }
      local result = list:flatten()

      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)

    it('should handle mixed nested and non-nested elements', function()
      local list = llx.List{1, llx.List{2, 3}, 4}
      local result = list:flatten()

      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4})
    end)
  end)

  describe('distinct', function()
    it('should remove duplicates', function()
      local list = llx.List{1, 2, 2, 3, 1, 4, 3, 5}
      local result = list:distinct()

      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)

    it('should use key function for uniqueness', function()
      local list = llx.List{
        {id=1, name='Alice'},
        {id=2, name='Bob'},
        {id=1, name='Alice2'}
      }
      local result = list:distinct(function(item) return item.id end)

      expect(#result).to.be_equal_to(2)
      expect(result[1].name).to.be_equal_to('Alice')
      expect(result[2].name).to.be_equal_to('Bob')
    end)
  end)

  describe('unique', function()
    it('should be alias for distinct', function()
      local list = llx.List{1, 2, 2, 3}
      local result1 = list:distinct()
      local result2 = list:unique()

      expect(result1).to.be_equal_to(result2)
    end)
  end)

  describe('any', function()
    it('should return true if any element matches', function()
      local list = llx.List{1, 2, 3, 4, 5}
      local result = list:any(function(x) return x > 3 end)

      expect(result).to.be_true()
    end)

    it('should return false if no elements match', function()
      local list = llx.List{1, 2, 3}
      local result = list:any(function(x) return x > 10 end)

      expect(result).to.be_false()
    end)
  end)

  describe('all', function()
    it('should return true if all elements match', function()
      local list = llx.List{2, 4, 6, 8}
      local result = list:all(function(x) return x % 2 == 0 end)

      expect(result).to.be_true()
    end)

    it('should return false if any element does not match', function()
      local list = llx.List{2, 4, 5, 8}
      local result = list:all(function(x) return x % 2 == 0 end)

      expect(result).to.be_false()
    end)
  end)

  describe('none', function()
    it('should return true if no elements match', function()
      local list = llx.List{1, 3, 5, 7}
      local result = list:none(function(x) return x % 2 == 0 end)

      expect(result).to.be_true()
    end)

    it('should return false if any element matches', function()
      local list = llx.List{1, 3, 4, 7}
      local result = list:none(function(x) return x % 2 == 0 end)

      expect(result).to.be_false()
    end)
  end)

  describe('take', function()
    it('should return first n elements', function()
      local list = llx.List{1, 2, 3, 4, 5}
      local result = list:take(3)

      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)

    it('should return all elements if n > length', function()
      local list = llx.List{1, 2, 3}
      local result = list:take(10)

      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('drop', function()
    it('should return elements after first n', function()
      local list = llx.List{1, 2, 3, 4, 5}
      local result = list:drop(2)

      expect(result).to.be_equal_to(llx.List{3, 4, 5})
    end)

    it('should return empty list if n >= length', function()
      local list = llx.List{1, 2, 3}
      local result = list:drop(10)

      expect(result).to.be_equal_to(llx.List{})
    end)
  end)

  describe('partition', function()
    it('should split into matches and non-matches', function()
      local list = llx.List{1, 2, 3, 4, 5, 6}
      local evens, odds = list:partition(function(x) return x % 2 == 0 end)

      expect(evens).to.be_equal_to(llx.List{2, 4, 6})
      expect(odds).to.be_equal_to(llx.List{1, 3, 5})
    end)
  end)

  describe('chunk', function()
    it('should split into chunks of size n', function()
      local list = llx.List{1, 2, 3, 4, 5, 6, 7}
      local result = list:chunk(3)

      expect(#result).to.be_equal_to(3)
      expect(result[1]).to.be_equal_to(llx.List{1, 2, 3})
      expect(result[2]).to.be_equal_to(llx.List{4, 5, 6})
      expect(result[3]).to.be_equal_to(llx.List{7})
    end)

    it('should throw error for chunk size < 1', function()
      local list = llx.List{1, 2, 3}

      expect(function()
        list:chunk(0)
      end).to.throw('Chunk size must be at least 1')
    end)
  end)

  describe('sum', function()
    it('should sum all elements', function()
      local list = llx.List{1, 2, 3, 4, 5}
      local result = list:sum()

      expect(result).to.be_equal_to(15)
    end)

    it('should return 0 for empty list', function()
      local list = llx.List{}
      local result = list:sum()

      expect(result).to.be_equal_to(0)
    end)
  end)

  describe('product', function()
    it('should multiply all elements', function()
      local list = llx.List{2, 3, 4}
      local result = list:product()

      expect(result).to.be_equal_to(24)
    end)

    it('should return 1 for empty list', function()
      local list = llx.List{}
      local result = list:product()

      expect(result).to.be_equal_to(1)
    end)
  end)

  describe('min', function()
    it('should find minimum element', function()
      local list = llx.List{3, 1, 4, 1, 5, 9, 2, 6}
      local result = list:min()

      expect(result).to.be_equal_to(1)
    end)

    it('should return nil for empty list', function()
      local list = llx.List{}
      local result = list:min()

      expect(result).to.be_nil()
    end)

    it('should use custom comparator', function()
      local list = llx.List{3, 1, 4, 1, 5}
      local result = list:min(function(a, b) return a > b end)

      expect(result).to.be_equal_to(5)
    end)
  end)

  describe('max', function()
    it('should find maximum element', function()
      local list = llx.List{3, 1, 4, 1, 5, 9, 2, 6}
      local result = list:max()

      expect(result).to.be_equal_to(9)
    end)

    it('should return nil for empty list', function()
      local list = llx.List{}
      local result = list:max()

      expect(result).to.be_nil()
    end)

    it('should use custom comparator', function()
      local list = llx.List{3, 1, 4, 1, 5}
      local result = list:max(function(a, b) return a < b end)

      expect(result).to.be_equal_to(1)
    end)
  end)

  describe('first', function()
    it('should return first element', function()
      local list = llx.List{1, 2, 3}
      local result = list:first()

      expect(result).to.be_equal_to(1)
    end)

    it('should return nil for empty list', function()
      local list = llx.List{}
      local result = list:first()

      expect(result).to.be_nil()
    end)
  end)

  describe('last', function()
    it('should return last element', function()
      local list = llx.List{1, 2, 3}
      local result = list:last()

      expect(result).to.be_equal_to(3)
    end)

    it('should return nil for empty list', function()
      local list = llx.List{}
      local result = list:last()

      expect(result).to.be_nil()
    end)
  end)

  describe('is_empty', function()
    it('should return true for empty list', function()
      local list = llx.List{}
      expect(list:is_empty()).to.be_true()
    end)

    it('should return false for non-empty list', function()
      local list = llx.List{1}
      expect(list:is_empty()).to.be_false()
    end)
  end)

  describe('method chaining', function()
    it('should support chaining multiple methods', function()
      local result = llx.List{1, 2, 3, 4, 5, 6}
        :filter(function(x) return x % 2 == 0 end)
        :map(function(x) return x * 2 end)
        :reduce(function(acc, x) return acc + x end, 0)

      expect(result).to.be_equal_to(24)
    end)

    it('should support complex chaining', function()
      local result = llx.List{1, 2, 3, 4, 5, 6, 7, 8}
        :filter(function(x) return x > 2 end)
        :map(function(x) return x * 2 end)
        :take(4)
        :sum()

      expect(result).to.be_equal_to(36)
    end)
  end)
end)

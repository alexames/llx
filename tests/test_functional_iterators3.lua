-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.functional'

_ENV = unit.create_test_env(_ENV)

describe('iteration utilities (tier 3)', function()
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

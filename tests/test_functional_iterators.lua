-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.operators'
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
end)

if llx.main_file() then
  unit.run_unit_tests()
end

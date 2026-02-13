local unit = require 'llx.unit'
local llx = require 'llx'
local tuple_module = require 'llx.tuple'
local hash = require 'llx.hash'

_ENV = unit.create_test_env(_ENV)

local Tuple = tuple_module.Tuple

describe('Tuple', function()
  describe('construction', function()
    it('should create a tuple from a list', function()
      local t = Tuple{1, 2, 3}
      expect(t).to_not.be_nil()
    end)

    it('should create an empty tuple', function()
      local t = Tuple{}
      expect(t).to_not.be_nil()
    end)

    it('should create a single-element tuple', function()
      local t = Tuple{'only'}
      expect(t[1]).to.be_equal_to('only')
    end)

    it('should store values of different types', function()
      local t = Tuple{1, 'two', true}
      expect(t[1]).to.be_equal_to(1)
      expect(t[2]).to.be_equal_to('two')
      expect(t[3]).to.be_true()
    end)
  end)

  describe('__index access', function()
    it('should access elements by numeric index', function()
      local t = Tuple{10, 20, 30}
      expect(t[1]).to.be_equal_to(10)
      expect(t[2]).to.be_equal_to(20)
      expect(t[3]).to.be_equal_to(30)
    end)

    it('should return nil for out-of-bounds index', function()
      local t = Tuple{1, 2}
      expect(t[3]).to.be_nil()
      expect(t[0]).to.be_nil()
    end)

    it('should return nil for negative index', function()
      local t = Tuple{1, 2, 3}
      expect(t[-1]).to.be_nil()
    end)

    it('should preserve element order', function()
      local t = Tuple{'a', 'b', 'c', 'd'}
      expect(t[1]).to.be_equal_to('a')
      expect(t[2]).to.be_equal_to('b')
      expect(t[3]).to.be_equal_to('c')
      expect(t[4]).to.be_equal_to('d')
    end)
  end)

  describe('__len', function()
    it('should return 0 for an empty tuple', function()
      local t = Tuple{}
      expect(#t).to.be_equal_to(0)
    end)

    it('should return the correct length for a non-empty tuple', function()
      local t = Tuple{1, 2, 3}
      expect(#t).to.be_equal_to(3)
    end)

    it('should return 1 for a single-element tuple', function()
      local t = Tuple{42}
      expect(#t).to.be_equal_to(1)
    end)

    it('should return correct length for a large tuple', function()
      local values = {}
      for i = 1, 100 do
        values[i] = i
      end
      local t = Tuple(values)
      expect(#t).to.be_equal_to(100)
    end)
  end)

  describe('__hash', function()
    it('should return a number', function()
      local t = Tuple{1, 2, 3}
      local h = hash.hash(t)
      expect(h).to.be_a('number')
    end)

    it('should be deterministic for the same content', function()
      local t1 = Tuple{1, 2, 3}
      local t2 = Tuple{1, 2, 3}
      expect(hash.hash(t1)).to.be_equal_to(hash.hash(t2))
    end)

    it('should produce different hashes for different content', function()
      local t1 = Tuple{1, 2, 3}
      local t2 = Tuple{4, 5, 6}
      expect(hash.hash(t1)).to_not.be_equal_to(hash.hash(t2))
    end)

    it('should produce different hashes for tuples '
      .. 'of different lengths', function()
      local t1 = Tuple{1, 2}
      local t2 = Tuple{1, 2, 3}
      expect(hash.hash(t1)).to_not.be_equal_to(hash.hash(t2))
    end)

    it('should produce different hashes for tuples with '
      .. 'same elements in different order', function()
      local t1 = Tuple{1, 2, 3}
      local t2 = Tuple{3, 2, 1}
      expect(hash.hash(t1)).to_not.be_equal_to(hash.hash(t2))
    end)

    it('should produce consistent hash for empty tuples', function()
      local t1 = Tuple{}
      local t2 = Tuple{}
      expect(hash.hash(t1)).to.be_equal_to(hash.hash(t2))
    end)

    it('should produce different hashes for tuples with '
      .. 'different element types', function()
      local t1 = Tuple{1, 2}
      local t2 = Tuple{'1', '2'}
      expect(hash.hash(t1)).to_not.be_equal_to(hash.hash(t2))
    end)
  end)

  describe('__newindex (immutability)', function()
    it('should error when trying to set a value', function()
      local t = Tuple{1, 2, 3}
      expect(function()
        t[1] = 99
      end).to.throw()
    end)

    it('should error when trying to add a new element', function()
      local t = Tuple{1, 2}
      expect(function()
        t[3] = 'new'
      end).to.throw()
    end)

    it('should error when trying to set a string key', function()
      local t = Tuple{1}
      expect(function()
        t['key'] = 'value'
      end).to.throw()
    end)
  end)

  describe('__tostring', function()
    it('should convert an empty tuple to string', function()
      local t = Tuple{}
      expect(tostring(t)).to.be_equal_to('Tuple{}')
    end)

    it('should convert a single-element tuple to string', function()
      local t = Tuple{42}
      expect(tostring(t)).to.be_equal_to('Tuple{42}')
    end)

    it('should convert a multi-element tuple to string', function()
      local t = Tuple{1, 2, 3}
      expect(tostring(t)).to.be_equal_to('Tuple{1,2,3}')
    end)

    it('should handle string elements in tostring', function()
      local t = Tuple{'a', 'b', 'c'}
      expect(tostring(t)).to.be_equal_to('Tuple{a,b,c}')
    end)
  end)

  describe('unpack', function()
    it('should unpack all elements', function()
      local t = Tuple{10, 20, 30}
      local a, b, c = t:unpack()
      expect(a).to.be_equal_to(10)
      expect(b).to.be_equal_to(20)
      expect(c).to.be_equal_to(30)
    end)

    it('should unpack a single element', function()
      local t = Tuple{42}
      local a = t:unpack()
      expect(a).to.be_equal_to(42)
    end)

    it('should unpack an empty tuple as no values', function()
      local t = Tuple{}
      local result = {t:unpack()}
      expect(#result).to.be_equal_to(0)
    end)

    it('should preserve order when unpacking', function()
      local t = Tuple{'x', 'y', 'z'}
      local a, b, c = t:unpack()
      expect(a).to.be_equal_to('x')
      expect(b).to.be_equal_to('y')
      expect(c).to.be_equal_to('z')
    end)
  end)

  describe('__lt and __le (lexicographic ordering)', function()
    it('should order by first differing element', function()
      expect(Tuple{1, 2, 3} < Tuple{1, 2, 4}).to.be_truthy()
      expect(Tuple{1, 2, 4} < Tuple{1, 2, 3}).to.be_falsy()
    end)

    it('should order shorter tuple before longer '
      .. 'when prefix matches', function()
      expect(Tuple{1, 2} < Tuple{1, 2, 3}).to.be_truthy()
      expect(Tuple{1, 2, 3} < Tuple{1, 2}).to.be_falsy()
    end)

    it('should not be less than an equal tuple', function()
      expect(Tuple{1, 2, 3} < Tuple{1, 2, 3}).to.be_falsy()
    end)

    it('should handle empty tuples', function()
      expect(Tuple{} < Tuple{1}).to.be_truthy()
      expect(Tuple{1} < Tuple{}).to.be_falsy()
      expect(Tuple{} < Tuple{}).to.be_falsy()
    end)

    it('should support <= for equal tuples', function()
      expect(Tuple{1, 2} <= Tuple{1, 2}).to.be_truthy()
    end)

    it('should support <= for less-than tuples', function()
      expect(Tuple{1, 2} <= Tuple{1, 3}).to.be_truthy()
    end)

    it('should support <= returning false '
      .. 'for greater tuples', function()
      expect(Tuple{1, 3} <= Tuple{1, 2}).to.be_falsy()
    end)

    it('should support > via negation of <=', function()
      expect(Tuple{2, 1} > Tuple{1, 2}).to.be_truthy()
      expect(Tuple{1, 2} > Tuple{2, 1}).to.be_falsy()
    end)

    it('should support >= via negation of <', function()
      expect(Tuple{1, 2} >= Tuple{1, 2}).to.be_truthy()
      expect(Tuple{1, 3} >= Tuple{1, 2}).to.be_truthy()
      expect(Tuple{1, 1} >= Tuple{1, 2}).to.be_falsy()
    end)

    it('should work with string elements', function()
      expect(Tuple{'a', 'b'} < Tuple{'a', 'c'}).to.be_truthy()
      expect(Tuple{'b', 'a'} < Tuple{'a', 'b'}).to.be_falsy()
    end)

    it('should allow sorting a list of tuples', function()
      local tuples = {
        Tuple{3, 1}, Tuple{1, 3}, Tuple{1, 2}, Tuple{2, 1}
      }
      table.sort(tuples)
      expect(tuples[1]).to.be_equal_to(Tuple{1, 2})
      expect(tuples[2]).to.be_equal_to(Tuple{1, 3})
      expect(tuples[3]).to.be_equal_to(Tuple{2, 1})
      expect(tuples[4]).to.be_equal_to(Tuple{3, 1})
    end)
  end)

  describe('isolation', function()
    it('should not be affected by changes to the original table', function()
      local input = {1, 2, 3}
      local t = Tuple(input)
      input[1] = 999
      expect(t[1]).to.be_equal_to(1)
    end)

    it('should create independent copies', function()
      local t1 = Tuple{1, 2, 3}
      local t2 = Tuple{1, 2, 3}
      expect(hash.hash(t1)).to.be_equal_to(hash.hash(t2))
      expect(t1[1]).to.be_equal_to(t2[1])
      expect(t1[2]).to.be_equal_to(t2[2])
      expect(t1[3]).to.be_equal_to(t2[3])
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

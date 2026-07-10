local unit = require 'llx.unit'
local llx = require 'llx'
local Counter = require 'llx.collections.counter' . Counter

local hash = require 'llx.hash' . hash
local HashTable = require 'llx.hash_table' . HashTable

_ENV = unit.create_test_env(_ENV)

describe('Counter', function()
  describe('construction', function()
    it('should create an empty counter', function()
      local c = Counter()
      expect(c:total()).to.be_equal_to(0)
      expect(#c).to.be_equal_to(0)
    end)

    it('should count from a sequence', function()
      local c = Counter{'a', 'b', 'a', 'c', 'a'}
      expect(c:get('a')).to.be_equal_to(3)
      expect(c:get('b')).to.be_equal_to(1)
      expect(c:get('c')).to.be_equal_to(1)
    end)

    it('should accept a map of explicit counts', function()
      local c = Counter{red = 5, blue = 3}
      expect(c:get('red')).to.be_equal_to(5)
      expect(c:get('blue')).to.be_equal_to(3)
    end)

    it('should count from an iterator', function()
      local function gen()
        local items = {'x', 'y', 'x', 'z', 'x', 'y'}
        local i = 0
        return function()
          i = i + 1
          if i > #items then return nil end
          return i, items[i]
        end
      end
      local c = Counter(gen())
      expect(c:get('x')).to.be_equal_to(3)
      expect(c:get('y')).to.be_equal_to(2)
      expect(c:get('z')).to.be_equal_to(1)
    end)

    it('should reject non-numeric values in map form', function()
      expect(function()
        Counter{a = 'not_a_number'}
      end).to.throw()
    end)
  end)

  describe('get and missing keys', function()
    it('should return 0 for missing keys', function()
      local c = Counter{'a'}
      expect(c:get('b')).to.be_equal_to(0)
      expect(c:get('never_seen')).to.be_equal_to(0)
    end)
  end)

  describe('increment and decrement', function()
    it('should add 1 by default', function()
      local c = Counter()
      c:increment('x')
      c:increment('x')
      expect(c:get('x')).to.be_equal_to(2)
    end)

    it('should add an explicit n', function()
      local c = Counter()
      c:increment('x', 5)
      expect(c:get('x')).to.be_equal_to(5)
    end)

    it('should decrement', function()
      local c = Counter{a = 10}
      c:decrement('a', 3)
      expect(c:get('a')).to.be_equal_to(7)
    end)

    it('should support negative counts via decrement', function()
      local c = Counter()
      c:decrement('x')
      expect(c:get('x')).to.be_equal_to(-1)
    end)
  end)

  describe('contains', function()
    it('should return true only for positive counts', function()
      local c = Counter{a = 1, b = 0, c = -1}
      expect(c:contains('a')).to.be_true()
      expect(c:contains('b')).to.be_false()
      expect(c:contains('c')).to.be_false()
      expect(c:contains('d')).to.be_false()
    end)
  end)

  describe('total', function()
    it('should sum all counts', function()
      local c = Counter{'a', 'a', 'b', 'b', 'c'}
      expect(c:total()).to.be_equal_to(5)
    end)
  end)

  describe('most_common', function()
    it('should sort by count descending', function()
      local c = Counter{'a', 'a', 'a', 'b', 'b', 'c'}
      local top = c:most_common()
      expect(top[1][1]).to.be_equal_to('a')
      expect(top[1][2]).to.be_equal_to(3)
      expect(top[2][1]).to.be_equal_to('b')
      expect(top[2][2]).to.be_equal_to(2)
      expect(top[3][1]).to.be_equal_to('c')
      expect(top[3][2]).to.be_equal_to(1)
    end)

    it('should limit to n items when given', function()
      local c = Counter{'a', 'a', 'a', 'b', 'b', 'c'}
      local top = c:most_common(2)
      expect(#top).to.be_equal_to(2)
      expect(top[1][1]).to.be_equal_to('a')
      expect(top[2][1]).to.be_equal_to('b')
    end)
  end)

  describe('elements iterator', function()
    it('should yield each key per its count', function()
      local c = Counter{a = 2, b = 1, c = 3}
      local seen = {a = 0, b = 0, c = 0}
      for _, v in c:elements() do
        seen[v] = seen[v] + 1
      end
      expect(seen.a).to.be_equal_to(2)
      expect(seen.b).to.be_equal_to(1)
      expect(seen.c).to.be_equal_to(3)
    end)

    it('should skip zero-count keys', function()
      local c = Counter{a = 2, b = 0}
      local seen = {a = 0, b = 0}
      for _, v in c:elements() do
        seen[v] = seen[v] + 1
      end
      expect(seen.a).to.be_equal_to(2)
      expect(seen.b).to.be_equal_to(0)
    end)
  end)

  describe('arithmetic', function()
    it('should merge via __add', function()
      local a = Counter{x = 1, y = 2}
      local b = Counter{y = 3, z = 4}
      local c = a + b
      expect(c:get('x')).to.be_equal_to(1)
      expect(c:get('y')).to.be_equal_to(5)
      expect(c:get('z')).to.be_equal_to(4)
    end)

    it('should subtract via __sub with negative clamping', function()
      local a = Counter{x = 5, y = 1}
      local b = Counter{x = 3, y = 5, z = 2}
      local c = a - b
      expect(c:get('x')).to.be_equal_to(2)
      expect(c:get('y')).to.be_equal_to(0)  -- 1 - 5 = -4 clamped to 0
      expect(c:get('z')).to.be_equal_to(0)  -- 0 - 2 = -2 clamped to 0
    end)
  end)

  describe('__eq, __hash, __tostring', function()
    it('should compare equal when counts match', function()
      expect(Counter{a = 1, b = 2} == Counter{b = 2, a = 1}).to.be_true()
    end)

    it('should treat zero-count keys as absent', function()
      expect(Counter{a = 1} == Counter{a = 1, b = 0}).to.be_true()
    end)

    it('should hash equal counters to the same value', function()
      expect(hash(Counter{a = 1, b = 2}))
        .to.be_equal_to(hash(Counter{b = 2, a = 1}))
    end)

    it('should be usable as a HashTable key', function()
      local ht = HashTable()
      ht[Counter{a = 1}] = 'one_a'
      expect(ht[Counter{a = 1}]).to.be_equal_to('one_a')
    end)

    it('should produce a Counter{...} tostring', function()
      expect(tostring(Counter{a = 1})).to.be_equal_to('Counter{a=1}')
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end

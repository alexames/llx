local unit = require 'llx.unit'
local llx = require 'llx'
local deque_module = require 'llx.collections.deque'
local Deque = deque_module.Deque

local hash = require 'llx.hash' . hash
local HashTable = require 'llx.hash_table' . HashTable

_ENV = unit.create_test_env(_ENV)

describe('Deque', function()
  describe('construction', function()
    it('should create an empty deque', function()
      local d = Deque()
      expect(#d).to.be_equal_to(0)
      expect(d:is_empty()).to.be_true()
    end)

    it('should populate from a list', function()
      local d = Deque{1, 2, 3}
      expect(#d).to.be_equal_to(3)
      expect(d:peek_left()).to.be_equal_to(1)
      expect(d:peek_right()).to.be_equal_to(3)
    end)

    it('should populate from an iterator', function()
      local function range_iter()
        local i = 0
        return function()
          i = i + 1
          if i > 3 then return nil end
          return i, i * 10
        end
      end
      local d = Deque(range_iter())
      expect(#d).to.be_equal_to(3)
      expect(d:at(1)).to.be_equal_to(10)
      expect(d:at(3)).to.be_equal_to(30)
    end)
  end)

  describe('push and pop on both ends', function()
    it('should push and pop on the right', function()
      local d = Deque()
      d:push_right('a')
      d:push_right('b')
      expect(d:pop_right()).to.be_equal_to('b')
      expect(d:pop_right()).to.be_equal_to('a')
      expect(d:is_empty()).to.be_true()
    end)

    it('should push and pop on the left', function()
      local d = Deque()
      d:push_left('a')
      d:push_left('b')
      expect(d:pop_left()).to.be_equal_to('b')
      expect(d:pop_left()).to.be_equal_to('a')
      expect(d:is_empty()).to.be_true()
    end)

    it('should interleave both-end operations correctly', function()
      local d = Deque()
      d:push_right(1)  -- [1]
      d:push_left(2)   -- [2, 1]
      d:push_right(3)  -- [2, 1, 3]
      d:push_left(4)   -- [4, 2, 1, 3]
      expect(d:pop_left()).to.be_equal_to(4)
      expect(d:pop_right()).to.be_equal_to(3)
      expect(d:pop_left()).to.be_equal_to(2)
      expect(d:pop_right()).to.be_equal_to(1)
      expect(d:is_empty()).to.be_true()
    end)

    it('push/pop should alias to right side', function()
      local d = Deque()
      d:push('a')
      d:push('b')
      expect(d:pop()).to.be_equal_to('b')
      expect(d:pop()).to.be_equal_to('a')
    end)

    it('should error on pop from empty deque', function()
      local d = Deque()
      expect(function() d:pop_right() end).to.throw()
      expect(function() d:pop_left() end).to.throw()
    end)
  end)

  describe('peek', function()
    it('should return nil from peek on empty deque', function()
      local d = Deque()
      expect(d:peek_left()).to.be_nil()
      expect(d:peek_right()).to.be_nil()
    end)

    it('should not mutate on peek', function()
      local d = Deque{1, 2, 3}
      d:peek_left()
      d:peek_right()
      expect(#d).to.be_equal_to(3)
    end)
  end)

  describe('contains and at', function()
    it('should report membership via contains', function()
      local d = Deque{'x', 'y', 'z'}
      expect(d:contains('y')).to.be_true()
      expect(d:contains('w')).to.be_false()
    end)

    it('should index with at(i) using 1-based positive indices', function()
      local d = Deque{'a', 'b', 'c'}
      expect(d:at(1)).to.be_equal_to('a')
      expect(d:at(3)).to.be_equal_to('c')
    end)

    it('should index with at(-i) using negative indices', function()
      local d = Deque{'a', 'b', 'c'}
      expect(d:at(-1)).to.be_equal_to('c')
      expect(d:at(-3)).to.be_equal_to('a')
    end)

    it('should error on out-of-range at()', function()
      local d = Deque{'a'}
      expect(function() d:at(2) end).to.throw()
      expect(function() d:at(0) end).to.throw()
    end)
  end)

  describe('clear', function()
    it('should empty the deque', function()
      local d = Deque{1, 2, 3}
      d:clear()
      expect(d:is_empty()).to.be_true()
      expect(#d).to.be_equal_to(0)
    end)
  end)

  describe('iteration via __call', function()
    it('should yield (index, value) pairs in order', function()
      local d = Deque{'a', 'b', 'c'}
      local out = {}
      for i, v in d do
        table.insert(out, i .. '=' .. v)
      end
      expect(table.concat(out, ',')).to.be_equal_to('1=a,2=b,3=c')
    end)
  end)

  describe('__eq, __hash, __tostring', function()
    it('should compare equal for same contents', function()
      expect(Deque{1, 2, 3} == Deque{1, 2, 3}).to.be_true()
    end)

    it('should compare unequal for different contents', function()
      expect(Deque{1, 2, 3} == Deque{1, 2, 4}).to.be_false()
    end)

    it('should hash equal for equal deques', function()
      expect(hash(Deque{1, 2, 3}))
        .to.be_equal_to(hash(Deque{1, 2, 3}))
    end)

    it('should be usable as a HashTable key', function()
      local ht = HashTable()
      ht[Deque{1, 2}] = 'pair'
      expect(ht[Deque{1, 2}]).to.be_equal_to('pair')
    end)

    it('should produce a Deque{...} tostring', function()
      expect(tostring(Deque{1, 2})).to.be_equal_to('Deque{1, 2}')
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end

local unit = require 'llx.unit'
local llx = require 'llx'
local DefaultDict = require 'llx.collections.default_dict' . DefaultDict
local hash = require 'llx.hash' . hash

_ENV = unit.create_test_env(_ENV)

describe('DefaultDict', function()
  describe('construction', function()
    it('should require a factory function', function()
      expect(function() DefaultDict(nil) end).to.throw()
      expect(function() DefaultDict('not_a_func') end).to.throw()
    end)

    it('should accept a factory and start empty', function()
      local dd = DefaultDict(function() return 0 end)
      expect(#dd).to.be_equal_to(0)
    end)
  end)

  describe('factory behavior', function()
    it('should create a default on first read', function()
      local dd = DefaultDict(function() return 'default' end)
      expect(dd:get('any_key')).to.be_equal_to('default')
    end)

    it('should store the created value for subsequent reads', function()
      local count = 0
      local dd = DefaultDict(function()
        count = count + 1
        return count
      end)
      expect(dd:get('a')).to.be_equal_to(1)
      expect(dd:get('a')).to.be_equal_to(1)  -- same value, no new call
      expect(count).to.be_equal_to(1)
    end)

    it('should pass the key to the factory', function()
      local dd = DefaultDict(function(k) return 'val_for_' .. k end)
      expect(dd:get('xyz')).to.be_equal_to('val_for_xyz')
    end)

    it('should support the table-of-lists pattern', function()
      local List = llx.List
      local groups = DefaultDict(function() return List{} end)
      groups:get('evens'):insert(2)
      groups:get('evens'):insert(4)
      groups:get('odds'):insert(1)
      expect(#groups:get('evens')).to.be_equal_to(2)
      expect(#groups:get('odds')).to.be_equal_to(1)
    end)
  end)

  describe('peek and contains', function()
    it('should return nil from peek without invoking factory', function()
      local count = 0
      local dd = DefaultDict(function() count = count + 1; return 0 end)
      expect(dd:peek('absent')).to.be_nil()
      expect(count).to.be_equal_to(0)
    end)

    it('should report contains correctly', function()
      local dd = DefaultDict(function() return 0 end)
      expect(dd:contains('x')).to.be_false()
      dd:get('x')
      expect(dd:contains('x')).to.be_true()
    end)

    it('contains should not trigger the factory', function()
      local count = 0
      local dd = DefaultDict(function() count = count + 1; return 0 end)
      dd:contains('absent')
      expect(count).to.be_equal_to(0)
    end)
  end)

  describe('set and delete', function()
    it('should set values directly', function()
      local dd = DefaultDict(function() return 0 end)
      dd:set('a', 42)
      expect(dd:peek('a')).to.be_equal_to(42)
    end)

    it('should delete values', function()
      local dd = DefaultDict(function() return 0 end)
      dd:set('a', 1)
      dd:delete('a')
      expect(dd:contains('a')).to.be_false()
    end)

    it('should re-trigger factory after delete', function()
      local count = 0
      local dd = DefaultDict(function() count = count + 1; return count end)
      dd:get('x')
      dd:delete('x')
      dd:get('x')
      expect(count).to.be_equal_to(2)
    end)
  end)

  describe('keys, values, clear', function()
    it('should list keys and values', function()
      local dd = DefaultDict(function() return 0 end)
      dd:set('a', 1)
      dd:set('b', 2)
      table.sort(dd:keys())
      expect(#dd:keys()).to.be_equal_to(2)
      expect(#dd:values()).to.be_equal_to(2)
    end)

    it('should clear all entries', function()
      local dd = DefaultDict(function() return 0 end)
      dd:set('a', 1)
      dd:clear()
      expect(#dd).to.be_equal_to(0)
    end)
  end)

  describe('iteration via __pairs', function()
    it('should iterate stored entries', function()
      local dd = DefaultDict(function() return 0 end)
      dd:set('a', 1)
      dd:set('b', 2)
      local sum = 0
      for _, v in pairs(dd) do sum = sum + v end
      expect(sum).to.be_equal_to(3)
    end)
  end)

  describe('__eq, __hash, __tostring', function()
    it('should compare equal for same data regardless of factory', function()
      local a = DefaultDict(function() return 0 end)
      local b = DefaultDict(function() return 999 end)
      a:set('x', 1)
      b:set('x', 1)
      expect(a == b).to.be_true()
    end)

    it('should compare unequal for different data', function()
      local a = DefaultDict(function() return 0 end)
      local b = DefaultDict(function() return 0 end)
      a:set('x', 1)
      b:set('x', 2)
      expect(a == b).to.be_false()
    end)

    it('should hash equal for equal data', function()
      local a = DefaultDict(function() return 0 end)
      local b = DefaultDict(function() return 0 end)
      a:set('x', 1) a:set('y', 2)
      b:set('y', 2) b:set('x', 1)
      expect(hash(a)).to.be_equal_to(hash(b))
    end)

    it('should produce a DefaultDict{...} tostring', function()
      local dd = DefaultDict(function() return 0 end)
      dd:set('x', 1)
      expect(tostring(dd)).to.be_equal_to('DefaultDict{x=1}')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

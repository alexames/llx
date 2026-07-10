local unit = require 'llx.unit'
local llx = require 'llx'
local OrderedDict = require 'llx.collections.ordered_dict' . OrderedDict

local hash = require 'llx.hash' . hash

_ENV = unit.create_test_env(_ENV)

describe('OrderedDict', function()
  describe('construction', function()
    it('should create empty', function()
      local od = OrderedDict()
      expect(#od).to.be_equal_to(0)
      expect(od:keys()).to.match_table({})
    end)

    it('should populate from a list of pairs in order', function()
      local od = OrderedDict{{'a', 1}, {'b', 2}, {'c', 3}}
      expect(od:keys()).to.match_table({'a', 'b', 'c'})
      expect(od:values()).to.match_table({1, 2, 3})
    end)

    it('should populate from an iterator yielding (k, v)', function()
      local function iter()
        local pairs_data = {{'x', 10}, {'y', 20}, {'z', 30}}
        local i = 0
        return function()
          i = i + 1
          if i > #pairs_data then return nil end
          return pairs_data[i][1], pairs_data[i][2]
        end
      end
      local od = OrderedDict(iter())
      expect(od:keys()).to.match_table({'x', 'y', 'z'})
    end)
  end)

  describe('set, get, contains', function()
    it('should set and get values', function()
      local od = OrderedDict()
      od:set('a', 1)
      od:set('b', 2)
      expect(od:get('a')).to.be_equal_to(1)
      expect(od:get('b')).to.be_equal_to(2)
    end)

    it('should return nil for missing keys', function()
      local od = OrderedDict()
      expect(od:get('nope')).to.be_nil()
    end)

    it('should report contains correctly', function()
      local od = OrderedDict{{'x', 1}}
      expect(od:contains('x')).to.be_true()
      expect(od:contains('y')).to.be_false()
    end)

    it('should preserve insertion order on update', function()
      local od = OrderedDict()
      od:set('a', 1)
      od:set('b', 2)
      od:set('a', 99)  -- update, not reinsert
      expect(od:keys()).to.match_table({'a', 'b'})
      expect(od:get('a')).to.be_equal_to(99)
    end)
  end)

  describe('delete', function()
    it('should remove a key', function()
      local od = OrderedDict{{'a', 1}, {'b', 2}, {'c', 3}}
      od:delete('b')
      expect(od:contains('b')).to.be_false()
      expect(#od).to.be_equal_to(2)
    end)

    it('should preserve order through middle deletes', function()
      -- The whole point of OrderedDict.
      local od = OrderedDict{{'a', 1}, {'b', 2}, {'c', 3}, {'d', 4}}
      od:delete('b')
      od:delete('c')
      expect(od:keys()).to.match_table({'a', 'd'})
    end)

    it('should preserve order through head and tail deletes', function()
      local od = OrderedDict{{'a', 1}, {'b', 2}, {'c', 3}}
      od:delete('a')
      expect(od:keys()).to.match_table({'b', 'c'})
      od:delete('c')
      expect(od:keys()).to.match_table({'b'})
    end)

    it('should return false for missing keys', function()
      local od = OrderedDict()
      expect(od:delete('nope')).to.be_false()
    end)

    it('should allow re-inserting after delete', function()
      local od = OrderedDict{{'a', 1}, {'b', 2}}
      od:delete('a')
      od:set('a', 99)  -- now goes to the end
      expect(od:keys()).to.match_table({'b', 'a'})
    end)
  end)

  describe('iteration via __pairs', function()
    it('should iterate in insertion order', function()
      local od = OrderedDict{{'first', 1}, {'second', 2}, {'third', 3}}
      local seen = {}
      for k, v in pairs(od) do
        seen[#seen + 1] = k .. '=' .. v
      end
      expect(table.concat(seen, ',')).to.be_equal_to(
        'first=1,second=2,third=3')
    end)

    it('should iterate in current order after deletes', function()
      local od = OrderedDict{{'a', 1}, {'b', 2}, {'c', 3}}
      od:delete('b')
      local keys = {}
      for k, _ in pairs(od) do keys[#keys + 1] = k end
      expect(table.concat(keys, ',')).to.be_equal_to('a,c')
    end)
  end)

  describe('move_to_end', function()
    it('should move an existing key to the end', function()
      local od = OrderedDict{{'a', 1}, {'b', 2}, {'c', 3}}
      od:move_to_end('a')
      expect(od:keys()).to.match_table({'b', 'c', 'a'})
    end)

    it('should be a no-op when key is already last', function()
      local od = OrderedDict{{'a', 1}, {'b', 2}}
      od:move_to_end('b')
      expect(od:keys()).to.match_table({'a', 'b'})
    end)

    it('should be a no-op for missing keys', function()
      local od = OrderedDict{{'a', 1}}
      od:move_to_end('nope')
      expect(od:keys()).to.match_table({'a'})
    end)
  end)

  describe('clear', function()
    it('should empty the dict', function()
      local od = OrderedDict{{'a', 1}, {'b', 2}}
      od:clear()
      expect(#od).to.be_equal_to(0)
      expect(od:keys()).to.match_table({})
    end)
  end)

  describe('__eq, __hash, __tostring', function()
    it('should be order-sensitive in equality', function()
      local a = OrderedDict{{'a', 1}, {'b', 2}}
      local b = OrderedDict{{'a', 1}, {'b', 2}}
      local c = OrderedDict{{'b', 2}, {'a', 1}}
      expect(a == b).to.be_true()
      expect(a == c).to.be_false()
    end)

    it('should hash equal for equal dicts', function()
      local a = OrderedDict{{'a', 1}, {'b', 2}}
      local b = OrderedDict{{'a', 1}, {'b', 2}}
      expect(hash(a)).to.be_equal_to(hash(b))
    end)

    it('should hash differently for different orders', function()
      local a = OrderedDict{{'a', 1}, {'b', 2}}
      local b = OrderedDict{{'b', 2}, {'a', 1}}
      expect(hash(a)).to_not.be_equal_to(hash(b))
    end)

    it('should produce an OrderedDict{...} tostring', function()
      local od = OrderedDict{{'a', 1}}
      expect(tostring(od)).to.be_equal_to('OrderedDict{a=1}')
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end

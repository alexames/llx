local unit = require 'llx.unit'
local llx = require 'llx'
local hash_table = require 'llx.hash_table'
local tuple_module = require 'llx.tuple'

_ENV = unit.create_test_env(_ENV)

local HashTable = hash_table.HashTable
local Tuple = tuple_module.Tuple

describe('HashTable', function()
  describe('construction', function()
    it('should create an empty hash table', function()
      local ht = HashTable()
      expect(ht).to_not.be_nil()
    end)

    it('should be a table type', function()
      local ht = HashTable()
      expect(type(ht)).to.be_equal_to('table')
    end)
  end)

  describe('get and set with string keys', function()
    it('should store and retrieve a value with a string key', function()
      local ht = HashTable()
      ht['hello'] = 42
      expect(ht['hello']).to.be_equal_to(42)
    end)

    it('should return nil for a key that was not set', function()
      local ht = HashTable()
      expect(ht['missing']).to.be_nil()
    end)

    it('should overwrite an existing key', function()
      local ht = HashTable()
      ht['key'] = 'first'
      ht['key'] = 'second'
      expect(ht['key']).to.be_equal_to('second')
    end)

    it('should store multiple keys independently', function()
      local ht = HashTable()
      ht['a'] = 1
      ht['b'] = 2
      ht['c'] = 3
      expect(ht['a']).to.be_equal_to(1)
      expect(ht['b']).to.be_equal_to(2)
      expect(ht['c']).to.be_equal_to(3)
    end)
  end)

  describe('get and set with number keys', function()
    it('should store and retrieve a value with a number key', function()
      local ht = HashTable()
      ht[1] = 'one'
      expect(ht[1]).to.be_equal_to('one')
    end)

    it('should handle multiple number keys', function()
      local ht = HashTable()
      ht[10] = 'ten'
      ht[20] = 'twenty'
      expect(ht[10]).to.be_equal_to('ten')
      expect(ht[20]).to.be_equal_to('twenty')
    end)
  end)

  describe('get and set with boolean keys', function()
    it('should store and retrieve a value with true as key', function()
      local ht = HashTable()
      ht[true] = 'yes'
      expect(ht[true]).to.be_equal_to('yes')
    end)

    it('should store and retrieve a value with false as key', function()
      local ht = HashTable()
      ht[false] = 'no'
      expect(ht[false]).to.be_equal_to('no')
    end)

    it('should differentiate between true and false keys', function()
      local ht = HashTable()
      ht[true] = 'yes'
      ht[false] = 'no'
      expect(ht[true]).to.be_equal_to('yes')
      expect(ht[false]).to.be_equal_to('no')
    end)
  end)

  describe('get and set with table keys', function()
    it('should store and retrieve using table keys '
      .. 'with same content', function()
      local ht = HashTable()
      ht[{1, 2, 3}] = 'list'
      expect(ht[{1, 2, 3}]).to.be_equal_to('list')
    end)

    it('should treat tables with same content as same key', function()
      local ht = HashTable()
      local key1 = {a = 1, b = 2}
      local key2 = {a = 1, b = 2}
      ht[key1] = 'value'
      expect(ht[key2]).to.be_equal_to('value')
    end)

    it('should treat tables with different content '
      .. 'as different keys', function()
      local ht = HashTable()
      ht[{a = 1}] = 'first'
      ht[{a = 2}] = 'second'
      expect(ht[{a = 1}]).to.be_equal_to('first')
      expect(ht[{a = 2}]).to.be_equal_to('second')
    end)
  end)

  describe('get and set with Tuple keys', function()
    it('should use Tuples as keys via __hash', function()
      local ht = HashTable()
      local t1 = Tuple{1, 2, 3}
      ht[t1] = 'tuple_value'
      expect(ht[t1]).to.be_equal_to('tuple_value')
    end)

    it('should retrieve value using a different Tuple '
      .. 'with same content', function()
      local ht = HashTable()
      local t1 = Tuple{10, 20}
      local t2 = Tuple{10, 20}
      ht[t1] = 'shared'
      expect(ht[t2]).to.be_equal_to('shared')
    end)

    it('should differentiate Tuples with different content', function()
      local ht = HashTable()
      local t1 = Tuple{1, 2}
      local t2 = Tuple{3, 4}
      ht[t1] = 'first'
      ht[t2] = 'second'
      expect(ht[t1]).to.be_equal_to('first')
      expect(ht[t2]).to.be_equal_to('second')
    end)
  end)

  describe('deletion', function()
    it('should delete a key by setting its value to nil', function()
      local ht = HashTable()
      ht['key'] = 'value'
      expect(ht['key']).to.be_equal_to('value')
      ht['key'] = nil
      expect(ht['key']).to.be_nil()
    end)

    it('should not affect other keys when deleting one', function()
      local ht = HashTable()
      ht['a'] = 1
      ht['b'] = 2
      ht['a'] = nil
      expect(ht['a']).to.be_nil()
      expect(ht['b']).to.be_equal_to(2)
    end)

    it('should handle deleting a non-existent key gracefully', function()
      local ht = HashTable()
      ht['nonexistent'] = nil
      expect(ht['nonexistent']).to.be_nil()
    end)
  end)

  describe('pairs iteration', function()
    it('should iterate over an empty hash table with no iterations', function()
      local ht = HashTable()
      local count = 0
      for k, v in pairs(ht) do
        count = count + 1
      end
      expect(count).to.be_equal_to(0)
    end)

    it('should return a function from pairs', function()
      local ht = HashTable()
      ht['x'] = 10
      local iter = pairs(ht)
      expect(type(iter)).to.be_equal_to('function')
    end)

    it('should yield a valid key-value pair on first iteration', function()
      local ht = HashTable()
      ht['only_key'] = 'only_value'
      local key, value
      for k, v in pairs(ht) do
        key = k
        value = v
        break
      end
      expect(key).to.be_equal_to('only_key')
      expect(value).to.be_equal_to('only_value')
    end)

    it('should return original keys, not hashed keys', function()
      local ht = HashTable()
      ht['original_key'] = 'value'
      local found_key = nil
      for k, v in pairs(ht) do
        found_key = k
        break
      end
      expect(found_key).to.be_equal_to('original_key')
    end)

    it('should yield entries with number keys', function()
      local ht = HashTable()
      ht[100] = 'hundred'
      local key, value
      for k, v in pairs(ht) do
        key = k
        value = v
        break
      end
      expect(key).to.be_equal_to(100)
      expect(value).to.be_equal_to('hundred')
    end)
  end)

  describe('value types', function()
    it('should store string values', function()
      local ht = HashTable()
      ht['k'] = 'string_value'
      expect(ht['k']).to.be_equal_to('string_value')
    end)

    it('should store number values', function()
      local ht = HashTable()
      ht['k'] = 3.14
      expect(ht['k']).to.be_equal_to(3.14)
    end)

    it('should store boolean values', function()
      local ht = HashTable()
      ht['k'] = true
      expect(ht['k']).to.be_true()
    end)

    it('should store table values', function()
      local ht = HashTable()
      local t = {1, 2, 3}
      ht['k'] = t
      expect(ht['k']).to.be_equal_to(t)
    end)

    it('should store function values', function()
      local ht = HashTable()
      local fn = function() return 42 end
      ht['k'] = fn
      expect(ht['k']).to.be_equal_to(fn)
    end)
  end)

  describe('mixed key types', function()
    it('should store values with string, number, and '
      .. 'boolean keys simultaneously', function()
      local ht = HashTable()
      ht['str'] = 'string_key'
      ht[42] = 'number_key'
      ht[true] = 'bool_key'

      expect(ht['str']).to.be_equal_to('string_key')
      expect(ht[42]).to.be_equal_to('number_key')
      expect(ht[true]).to.be_equal_to('bool_key')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

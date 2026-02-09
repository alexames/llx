-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.list'
require 'llx.types.table'

_ENV = unit.create_test_env(_ENV)

describe('table utilities', function()
  describe('keys', function()
    it('should return all keys as a list', function()
      local t = {a = 1, b = 2, c = 3}
      local result = llx.Table.keys(t):sort()
      expect(result).to.be_equal_to(llx.List{'a', 'b', 'c'})
    end)

    it('should return empty list for empty table', function()
      local result = llx.Table.keys({})
      expect(#result).to.be_equal_to(0)
    end)

    it('should include integer keys', function()
      local t = {10, 20, 30}
      local result = llx.Table.keys(t):sort()
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('entries', function()
    it('should return key-value pairs as a list of lists', function()
      local t = {x = 10, y = 20}
      local result = llx.Table.entries(t):sort(function(a, b) return a[1] < b[1] end)
      expect(result[1]).to.be_equal_to(llx.List{'x', 10})
      expect(result[2]).to.be_equal_to(llx.List{'y', 20})
    end)

    it('should return empty list for empty table', function()
      local result = llx.Table.entries({})
      expect(#result).to.be_equal_to(0)
    end)
  end)

  describe('from_entries', function()
    it('should construct a table from key-value pairs', function()
      local pairs_list = {{'a', 1}, {'b', 2}, {'c', 3}}
      local result = llx.Table.from_entries(pairs_list)
      expect(result.a).to.be_equal_to(1)
      expect(result.b).to.be_equal_to(2)
      expect(result.c).to.be_equal_to(3)
    end)

    it('should return empty table for empty input', function()
      local result = llx.Table.from_entries({})
      expect(next(result)).to.be_nil()
    end)

    it('should be the inverse of entries', function()
      local original = {x = 10, y = 20}
      local reconstructed = llx.Table.from_entries(llx.Table.entries(original))
      expect(reconstructed.x).to.be_equal_to(10)
      expect(reconstructed.y).to.be_equal_to(20)
    end)
  end)

  describe('merge', function()
    it('should merge two tables', function()
      local a = {x = 1, y = 2}
      local b = {y = 3, z = 4}
      local result = llx.Table.merge(a, b)
      expect(result.x).to.be_equal_to(1)
      expect(result.y).to.be_equal_to(3)
      expect(result.z).to.be_equal_to(4)
    end)

    it('should merge multiple tables left-to-right', function()
      local a = {x = 1}
      local b = {x = 2, y = 2}
      local c = {x = 3, z = 3}
      local result = llx.Table.merge(a, b, c)
      expect(result.x).to.be_equal_to(3)
      expect(result.y).to.be_equal_to(2)
      expect(result.z).to.be_equal_to(3)
    end)

    it('should not modify the input tables', function()
      local a = {x = 1}
      local b = {y = 2}
      llx.Table.merge(a, b)
      expect(a.y).to.be_nil()
      expect(b.x).to.be_nil()
    end)
  end)

  describe('pick', function()
    it('should select only the specified keys', function()
      local t = {a = 1, b = 2, c = 3, d = 4}
      local result = llx.Table.pick(t, {'a', 'c'})
      expect(result.a).to.be_equal_to(1)
      expect(result.c).to.be_equal_to(3)
      expect(result.b).to.be_nil()
      expect(result.d).to.be_nil()
    end)

    it('should ignore keys not present in the table', function()
      local t = {a = 1}
      local result = llx.Table.pick(t, {'a', 'z'})
      expect(result.a).to.be_equal_to(1)
      expect(result.z).to.be_nil()
    end)
  end)

  describe('omit', function()
    it('should exclude the specified keys', function()
      local t = {a = 1, b = 2, c = 3}
      local result = llx.Table.omit(t, {'b'})
      expect(result.a).to.be_equal_to(1)
      expect(result.c).to.be_equal_to(3)
      expect(result.b).to.be_nil()
    end)

    it('should return all keys when none are excluded', function()
      local t = {a = 1, b = 2}
      local result = llx.Table.omit(t, {})
      expect(result.a).to.be_equal_to(1)
      expect(result.b).to.be_equal_to(2)
    end)
  end)

  describe('invert', function()
    it('should swap keys and values', function()
      local t = {a = 1, b = 2, c = 3}
      local result = llx.Table.invert(t)
      expect(result[1]).to.be_equal_to('a')
      expect(result[2]).to.be_equal_to('b')
      expect(result[3]).to.be_equal_to('c')
    end)

    it('should be its own inverse for bijective tables', function()
      local t = {a = 'x', b = 'y'}
      local result = llx.Table.invert(llx.Table.invert(t))
      expect(result.a).to.be_equal_to('x')
      expect(result.b).to.be_equal_to('y')
    end)
  end)

  describe('size', function()
    it('should count all key-value pairs', function()
      local t = {a = 1, b = 2, c = 3}
      expect(llx.Table.size(t)).to.be_equal_to(3)
    end)

    it('should count mixed integer and string keys', function()
      local t = {10, 20, x = 30}
      expect(llx.Table.size(t)).to.be_equal_to(3)
    end)

    it('should return 0 for empty table', function()
      expect(llx.Table.size({})).to.be_equal_to(0)
    end)
  end)

  describe('is_empty', function()
    it('should return true for empty table', function()
      expect(llx.Table.is_empty({})).to.be_true()
    end)

    it('should return false for non-empty table', function()
      expect(llx.Table.is_empty({a = 1})).to.be_false()
    end)

    it('should return false for array table', function()
      expect(llx.Table.is_empty({1})).to.be_false()
    end)
  end)

  describe('map_keys', function()
    it('should transform all keys', function()
      local t = {a = 1, b = 2}
      local result = llx.Table.map_keys(t, string.upper)
      expect(result.A).to.be_equal_to(1)
      expect(result.B).to.be_equal_to(2)
      expect(result.a).to.be_nil()
    end)

    it('should return empty table for empty input', function()
      local result = llx.Table.map_keys({}, tostring)
      expect(next(result)).to.be_nil()
    end)
  end)

  describe('map_values', function()
    it('should transform all values', function()
      local t = {a = 1, b = 2, c = 3}
      local result = llx.Table.map_values(t, function(v) return v * 10 end)
      expect(result.a).to.be_equal_to(10)
      expect(result.b).to.be_equal_to(20)
      expect(result.c).to.be_equal_to(30)
    end)

    it('should return empty table for empty input', function()
      local result = llx.Table.map_values({}, tostring)
      expect(next(result)).to.be_nil()
    end)
  end)

  describe('defaults', function()
    it('should fill in missing keys from defaults', function()
      local t = {a = 1}
      local result = llx.Table.defaults(t, {a = 99, b = 2, c = 3})
      expect(result.a).to.be_equal_to(1)
      expect(result.b).to.be_equal_to(2)
      expect(result.c).to.be_equal_to(3)
    end)

    it('should accept multiple default tables', function()
      local result = llx.Table.defaults({a = 1}, {b = 2}, {b = 99, c = 3})
      expect(result.a).to.be_equal_to(1)
      expect(result.b).to.be_equal_to(2)
      expect(result.c).to.be_equal_to(3)
    end)

    it('should not modify the input table', function()
      local t = {a = 1}
      llx.Table.defaults(t, {b = 2})
      expect(t.b).to.be_nil()
    end)
  end)

  describe('deep_equal', function()
    it('should return true for identical flat tables', function()
      expect(llx.Table.deep_equal({a = 1, b = 2}, {a = 1, b = 2})).to.be_true()
    end)

    it('should return false for different values', function()
      expect(llx.Table.deep_equal({a = 1}, {a = 2})).to.be_false()
    end)

    it('should return false for different keys', function()
      expect(llx.Table.deep_equal({a = 1}, {b = 1})).to.be_false()
    end)

    it('should compare nested tables recursively', function()
      local a = {x = {y = {z = 1}}}
      local b = {x = {y = {z = 1}}}
      expect(llx.Table.deep_equal(a, b)).to.be_true()
    end)

    it('should detect nested differences', function()
      local a = {x = {y = 1}}
      local b = {x = {y = 2}}
      expect(llx.Table.deep_equal(a, b)).to.be_false()
    end)

    it('should return true for two empty tables', function()
      expect(llx.Table.deep_equal({}, {})).to.be_true()
    end)

    it('should return false for different sizes', function()
      expect(llx.Table.deep_equal({1, 2}, {1, 2, 3})).to.be_false()
    end)
  end)

  describe('get_in', function()
    it('should access a nested value via a path', function()
      local t = {a = {b = {c = 42}}}
      expect(llx.Table.get_in(t, {'a', 'b', 'c'})).to.be_equal_to(42)
    end)

    it('should return nil for a missing intermediate key', function()
      local t = {a = {b = 1}}
      expect(llx.Table.get_in(t, {'a', 'x', 'y'})).to.be_nil()
    end)

    it('should return nil for a missing leaf key', function()
      local t = {a = {b = 1}}
      expect(llx.Table.get_in(t, {'a', 'z'})).to.be_nil()
    end)

    it('should handle single-element paths', function()
      local t = {x = 10}
      expect(llx.Table.get_in(t, {'x'})).to.be_equal_to(10)
    end)

    it('should handle numeric keys', function()
      local t = {{10, 20}, {30, 40}}
      expect(llx.Table.get_in(t, {2, 1})).to.be_equal_to(30)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

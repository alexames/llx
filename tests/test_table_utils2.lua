-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.list'
require 'llx.types.table'

_ENV = unit.create_test_env(_ENV)

describe('table utilities (tier 2)', function()
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

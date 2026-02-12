-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.table'

_ENV = unit.create_test_env(_ENV)

describe('Table', function()
  describe('deepcopy', function()
    it('should create a deep copy of a table', function()
      local original = {a = 1, b = {c = 2, d = {e = 3}}}
      local copy = llx.Table.deepcopy(original)

      expect(copy).to.match_table(original)
      expect(copy).to_not.be_equal_to(original) -- Different objects
      -- Nested table is also copied
      expect(copy.b).to_not.be_equal_to(original.b)
      -- Deeply nested table is copied
      expect(copy.b.d).to_not.be_equal_to(original.b.d)
    end)

    it('should handle circular references', function()
      local original = {a = 1}
      original.b = original -- Circular reference
      local copy = llx.Table.deepcopy(original)

      expect(copy.a).to.be_equal_to(1)
      expect(copy.b).to.be_equal_to(copy) -- Should point to copy, not original
      expect(copy.b).to_not.be_equal_to(original)
    end)

    it('should handle empty tables', function()
      local original = {}
      local copy = llx.Table.deepcopy(original)

      expect(copy).to.match_table({})
      expect(copy).to_not.be_equal_to(original)
    end)

    it('should copy to destination if provided', function()
      local original = {a = 1, b = 2}
      local destination = {c = 3}
      local copy = llx.Table.deepcopy(original, destination)

      expect(copy).to.be_equal_to(destination)
      expect(copy.a).to.be_equal_to(1)
      expect(copy.b).to.be_equal_to(2)
      expect(copy.c).to.be_equal_to(3)
    end)

    it('should handle arrays', function()
      local original = {1, 2, {3, 4}}
      local copy = llx.Table.deepcopy(original)

      expect(copy).to.match_table(original)
      expect(copy[3]).to_not.be_equal_to(original[3]) -- Nested array is copied
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

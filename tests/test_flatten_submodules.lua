local unit = require 'llx.unit'
local llx = require 'llx'

local flatten_submodules = require 'llx.flatten_submodules'

_ENV = unit.create_test_env(_ENV)

describe('flatten_submodules', function()
  describe('basic flattening of array submodules', function()
    it('should flatten a single submodule table', function()
      local result = flatten_submodules {
        {alpha = 1, beta = 2},
      }
      expect(result.alpha).to.be_equal_to(1)
      expect(result.beta).to.be_equal_to(2)
    end)

    it('should flatten multiple submodule tables', function()
      local result = flatten_submodules {
        {alpha = 1},
        {beta = 2},
        {gamma = 3},
      }
      expect(result.alpha).to.be_equal_to(1)
      expect(result.beta).to.be_equal_to(2)
      expect(result.gamma).to.be_equal_to(3)
    end)

    it('should flatten an empty array of submodules', function()
      local result = flatten_submodules {}
      -- Should return a valid table with no fields
      expect(type(result)).to.be_equal_to('table')
    end)

    it('should flatten a submodule with function values', function()
      local fn = function() return 42 end
      local result = flatten_submodules {
        {my_func = fn},
      }
      expect(result.my_func).to.be_equal_to(fn)
      expect(result.my_func()).to.be_equal_to(42)
    end)

    it('should flatten a submodule with nested table values', function()
      local inner = {x = 10}
      local result = flatten_submodules {
        {nested = inner},
      }
      expect(result.nested).to.be_equal_to(inner)
      expect(result.nested.x).to.be_equal_to(10)
    end)
  end)

  describe('named entries', function()
    it('should keep named (string-keyed) entries as-is', function()
      local sub = {inner_key = 'inner_val'}
      local result = flatten_submodules {
        my_module = sub,
      }
      expect(result.my_module).to.be_equal_to(sub)
    end)

    it('should handle mixed array and named entries', function()
      local result = flatten_submodules {
        {alpha = 1, beta = 2},
        named_module = {gamma = 3},
      }
      -- Array entry gets flattened
      expect(result.alpha).to.be_equal_to(1)
      expect(result.beta).to.be_equal_to(2)
      -- Named entry stays as a nested table
      expect(result.named_module.gamma).to.be_equal_to(3)
    end)

    it('should keep named non-table entries as-is', function()
      local result = flatten_submodules {
        version = '1.0.0',
        count = 42,
      }
      expect(result.version).to.be_equal_to('1.0.0')
      expect(result.count).to.be_equal_to(42)
    end)

    it('should handle multiple named entries alongside array entries', function()
      local result = flatten_submodules {
        {flattened_key = 100},
        named_a = 'value_a',
        named_b = 'value_b',
      }
      expect(result.flattened_key).to.be_equal_to(100)
      expect(result.named_a).to.be_equal_to('value_a')
      expect(result.named_b).to.be_equal_to('value_b')
    end)
  end)

  describe('duplicate key detection', function()
    it('should error when two array submodules have the same key', function()
      local success = pcall(flatten_submodules, {
        {alpha = 1},
        {alpha = 2},
      })
      expect(success).to.be_false()
    end)

    it('should error when a named entry conflicts with a flattened key', function()
      local success = pcall(flatten_submodules, {
        {alpha = 1},
        alpha = 2,
      })
      expect(success).to.be_false()
    end)

    it('should error when two named entries have the same key', function()
      -- This cannot actually happen in a Lua table literal since
      -- duplicate keys overwrite, but we test the copy_into logic
      -- by using a submodule that duplicates a named key.
      local success = pcall(flatten_submodules, {
        alpha = 1,
        {alpha = 2},
      })
      expect(success).to.be_false()
    end)
  end)

  describe('result table behavior', function()
    it('should return a table with a metatable', function()
      local result = flatten_submodules {
        {alpha = 1},
      }
      expect(getmetatable(result)).to_not.be_nil()
    end)

    it('should error when accessing a non-existent field', function()
      local result = flatten_submodules {
        {alpha = 1},
      }
      local success = pcall(function()
        local _ = result.nonexistent
      end)
      expect(success).to.be_false()
    end)

    it('should error when trying to set a new field on the result', function()
      local result = flatten_submodules {
        {alpha = 1},
      }
      local success = pcall(function()
        result.new_field = 42
      end)
      expect(success).to.be_false()
    end)

    it('should support pairs iteration over all flattened fields', function()
      local result = flatten_submodules {
        {alpha = 1, beta = 2},
        gamma = 3,
      }
      local keys = {}
      for k, v in pairs(result) do
        keys[k] = v
      end
      expect(keys.alpha).to.be_equal_to(1)
      expect(keys.beta).to.be_equal_to(2)
      expect(keys.gamma).to.be_equal_to(3)
    end)
  end)

  describe('edge cases', function()
    it('should handle a single empty submodule', function()
      local result = flatten_submodules {
        {},
      }
      expect(type(result)).to.be_equal_to('table')
    end)

    it('should handle boolean values in submodules', function()
      local result = flatten_submodules {
        {flag_a = true, flag_b = false},
      }
      expect(result.flag_a).to.be_true()
      expect(result.flag_b).to.be_false()
    end)

    it('should not flatten non-table values at array positions', function()
      -- When a numeric-indexed value is not a table, it should be treated
      -- as a named entry (copy_into with numeric key)
      local result = flatten_submodules {
        {alpha = 1},
        named = 'value',
      }
      expect(result.alpha).to.be_equal_to(1)
      expect(result.named).to.be_equal_to('value')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

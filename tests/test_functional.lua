-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.debug.trace'
require 'llx.operators'
require 'llx.types.list'
require 'llx.types.table'
require 'llx.types.string'

_ENV = unit.create_test_env(_ENV)

describe('functional', function()
  describe('range', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- range(a, b, c)
    end)
  end)

  describe('generator', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- generator(iterator, state, control, closing)
    end)
  end)

  describe('map', function()
    it('should work', function(...)
      -- TODO: Add actual test implementation
      -- map(lambda, ...)
    end)
  end)

  describe('filter', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- filter(lambda, sequence)
    end)
  end)

  describe('count', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- count(start, step)
    end)
  end)

  describe('cycle', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- cycle(sequence)
    end)
  end)

  describe('repeat_elem', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- repeat_elem()
    end)
  end)

  describe('accumulate', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- accumulate(sequence, lambda, initial_value)
    end)
  end)

  describe('batched', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- batched(iterable, n)
    end)
  end)

  describe('chain', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- chain()
    end)
  end)

  describe('compress', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- compress()
    end)
  end)

  describe('drop_while', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- drop_while()
    end)
  end)

  describe('filterfalse', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- filterfalse()
    end)
  end)

  describe('group_by', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- group_by()
    end)
  end)

  describe('slice', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- slice()
    end)
  end)

  describe('pairwise', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- pairwise()
    end)
  end)

  describe('star_map', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- star_map()
    end)
  end)

  describe('take_while', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- take_while()
    end)
  end)

  describe('tee', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- tee()
    end)
  end)

  describe('zip_longest', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- zip_longest()
    end)
  end)

  describe('permutations', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- permutations()
    end)
  end)

  describe('combinations', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- combinations()
    end)
  end)

  describe('reduce', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- reduce(sequence, lambda, initial_value)
    end)
  end)

  describe('min', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- min(sequence)
    end)
  end)

  describe('max', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- max(sequence)
    end)
  end)

  describe('sum', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- sum(sequence)
    end)
  end)

  describe('product', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- product(sequence)
    end)
  end)

  describe('zip_impl', function()
    it('should work', function()
      -- TODO: Add actual test implementation
      -- zip_impl(iterators, result_handler)
    end)
  end)

  describe('zip_packed', function()
    it('should work', function(...)
      -- TODO: Add actual test implementation
      -- zip_packed(...)
    end)
  end)

  describe('zip', function()
    it('should work', function(...)
      -- TODO: Add actual test implementation
      -- zip(...)
    end)
  end)

  describe('cartesian_product', function()
    it('should work', function(...)
      -- TODO: Add actual test implementation
      -- cartesian_product(...)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.core'
require 'llx.types.list'

_ENV = unit.create_test_env(_ENV)

describe('functional iterators (tier 2)', function()
  describe('compact', function()
    it('should remove nil values from a sequence', function()
      local result = llx.List{}
      for _, v in llx.functional.compact(llx.List{1, nil, 2, nil, 3}) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)

    it('should remove false values', function()
      local result = llx.List{}
      for _, v in llx.functional.compact(llx.List{false, 0, '', true}) do
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{0, '', true})
    end)
  end)

  describe('shuffle', function()
    it('should return a List with the same elements', function()
      local input = llx.List{1, 2, 3, 4, 5}
      local result = llx.functional.shuffle(input)
      expect(#result).to.be_equal_to(5)
      local sorted_result = result:sort()
      expect(sorted_result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)

    it('should not modify the original list', function()
      local input = llx.List{1, 2, 3}
      llx.functional.shuffle(input)
      expect(input).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)

  describe('sample', function()
    it('should return n elements from the sequence', function()
      local input = llx.List{1, 2, 3, 4, 5}
      local result = llx.functional.sample(input, 3)
      expect(#result).to.be_equal_to(3)
    end)

    it('should return all elements when n equals length', function()
      local input = llx.List{1, 2, 3}
      local result = llx.functional.sample(input, 3)
      expect(#result).to.be_equal_to(3)
    end)

    it('should return elements from the original sequence', function()
      local input = llx.List{10, 20, 30, 40, 50}
      local result = llx.functional.sample(input, 2)
      for _, v in result do
        local found = false
        for _, u in input do
          if u == v then found = true; break end
        end
        expect(found).to.be_true()
      end
    end)
  end)

  describe('sorted', function()
    it('should return a sorted List from an iterator', function()
      local result = llx.functional.sorted(llx.List{3, 1, 4, 1, 5})
      expect(result).to.be_equal_to(llx.List{1, 1, 3, 4, 5})
    end)

    it('should accept a custom comparator', function()
      local result = llx.functional.sorted(llx.List{3, 1, 4}, function(a, b) return a > b end)
      expect(result).to.be_equal_to(llx.List{4, 3, 1})
    end)

    it('should not modify the input', function()
      local input = llx.List{3, 1, 2}
      llx.functional.sorted(input)
      expect(input[1]).to.be_equal_to(3)
    end)
  end)

  describe('iterate', function()
    it('should generate a sequence from repeated application', function()
      local result = llx.List{}
      local iter = llx.functional.iterate(function(x) return x * 2 end, 1)
      for i = 1, 5 do
        local _, v = iter()
        result:insert(v)
      end
      expect(result).to.be_equal_to(llx.List{1, 2, 4, 8, 16})
    end)
  end)

  describe('sort_by', function()
    it('should sort by a key function', function()
      local input = llx.List{{name='Charlie'}, {name='Alice'}, {name='Bob'}}
      local result = llx.functional.sort_by(input, function(x) return x.name end)
      expect(result[1].name).to.be_equal_to('Alice')
      expect(result[2].name).to.be_equal_to('Bob')
      expect(result[3].name).to.be_equal_to('Charlie')
    end)

    it('should not modify the original list', function()
      local input = llx.List{3, 1, 2}
      llx.functional.sort_by(input, function(x) return x end)
      expect(input[1]).to.be_equal_to(3)
    end)
  end)

  describe('min_by', function()
    it('should return the element with the minimum key', function()
      local input = llx.List{{val=3}, {val=1}, {val=2}}
      local result = llx.functional.min_by(input, function(x) return x.val end)
      expect(result.val).to.be_equal_to(1)
    end)
  end)

  describe('max_by', function()
    it('should return the element with the maximum key', function()
      local input = llx.List{{val=3}, {val=1}, {val=2}}
      local result = llx.functional.max_by(input, function(x) return x.val end)
      expect(result.val).to.be_equal_to(3)
    end)
  end)

  describe('flatten_deep', function()
    it('should flatten nested lists recursively', function()
      local result = llx.functional.flatten_deep(llx.List{1, llx.List{2, llx.List{3, 4}}, 5})
      expect(result).to.be_equal_to(llx.List{1, 2, 3, 4, 5})
    end)

    it('should flatten to a specific depth', function()
      local result = llx.functional.flatten_deep(
        llx.List{1, llx.List{2, llx.List{3, llx.List{4}}}}, 1)
      expect(result).to.be_equal_to(llx.List{1, 2, llx.List{3, llx.List{4}}})
    end)

    it('should return a flat list unchanged', function()
      local result = llx.functional.flatten_deep(llx.List{1, 2, 3})
      expect(result).to.be_equal_to(llx.List{1, 2, 3})
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.operators'

_ENV = unit.create_test_env(_ENV)

describe('operators (tier 2)', function()
  describe('gt', function()
    it('should return true when a > b', function()
      expect(llx.operators.gt(3, 2)).to.be_true()
    end)

    it('should return false when a <= b', function()
      expect(llx.operators.gt(2, 3)).to.be_false()
      expect(llx.operators.gt(2, 2)).to.be_false()
    end)
  end)

  describe('ge', function()
    it('should return true when a >= b', function()
      expect(llx.operators.ge(3, 2)).to.be_true()
      expect(llx.operators.ge(2, 2)).to.be_true()
    end)

    it('should return false when a < b', function()
      expect(llx.operators.ge(2, 3)).to.be_false()
    end)
  end)

  describe('ne', function()
    it('should return true when a ~= b', function()
      expect(llx.operators.ne(1, 2)).to.be_true()
    end)

    it('should return false when a == b', function()
      expect(llx.operators.ne(1, 1)).to.be_false()
    end)

    it('should work with strings', function()
      expect(llx.operators.ne('a', 'b')).to.be_true()
      expect(llx.operators.ne('a', 'a')).to.be_false()
    end)
  end)

  describe('itemgetter', function()
    it('should return a function that gets a single key', function()
      local get_name = llx.operators.itemgetter('name')
      expect(get_name({name = 'Alice', age = 30})).to.be_equal_to('Alice')
    end)

    it('should work with numeric keys', function()
      local get_first = llx.operators.itemgetter(1)
      expect(get_first({10, 20, 30})).to.be_equal_to(10)
    end)

    it('should return nil for missing keys', function()
      local get_x = llx.operators.itemgetter('x')
      expect(get_x({a = 1})).to.be_nil()
    end)

    it('should be usable as a key function for sort_by', function()
      local data = llx.List{{age=30}, {age=20}, {age=25}}
      local result = llx.functional.sort_by(data, llx.operators.itemgetter('age'))
      expect(result[1].age).to.be_equal_to(20)
      expect(result[2].age).to.be_equal_to(25)
      expect(result[3].age).to.be_equal_to(30)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

local unit = require 'llx.unit'
local llx = require 'llx'

local enum = require 'llx.enum' . enum

_ENV = unit.create_test_env(_ENV)

describe('enum', function()
  describe('creation', function()
    it('should create an enum with the given name', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      expect(Color.__name).to.be_equal_to('Color')
    end)

    it('should return a table', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      expect(type(Color)).to.be_equal_to('table')
    end)

    it('should require a name', function()
      expect(function()
        enum(nil) {}
      end).to.throw()
    end)
  end)

  describe('bidirectional lookup by index', function()
    it('should look up enum value by numeric index', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      local val = Color[1]
      expect(val).to_not.be_nil()
    end)

    it('should have the correct name for a value looked up by index', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      local val = Color[1]
      expect(val.name).to.be_equal_to('Red')
    end)

    it('should have the correct numeric value for a value looked up by index', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      local val = Color[1]
      expect(val.value).to.be_equal_to(1)
    end)

    it('should look up all indices correctly', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      expect(Color[1].name).to.be_equal_to('Red')
      expect(Color[2].name).to.be_equal_to('Green')
      expect(Color[3].name).to.be_equal_to('Blue')
    end)
  end)

  describe('bidirectional lookup by name', function()
    it('should look up enum value by string name', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      local val = Color['Red']
      expect(val).to_not.be_nil()
    end)

    it('should have the correct numeric value when looked up by name', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      expect(Color['Red'].value).to.be_equal_to(1)
      expect(Color['Green'].value).to.be_equal_to(2)
      expect(Color['Blue'].value).to.be_equal_to(3)
    end)

    it('should have the correct name when looked up by name', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      expect(Color['Red'].name).to.be_equal_to('Red')
    end)

    it('should dot-access enum members by name', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      expect(Color.Red).to_not.be_nil()
      expect(Color.Red.value).to.be_equal_to(1)
    end)
  end)

  describe('identity between index and name lookups', function()
    it('should return the same enum object for index and name lookups', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      expect(Color[1]).to.be_equal_to(Color['Red'])
      expect(Color[2]).to.be_equal_to(Color['Green'])
      expect(Color[3]).to.be_equal_to(Color['Blue'])
    end)
  end)

  describe('__tostring', function()
    it('should produce a tostring with the enum name and value name', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      local s = tostring(Color[1])
      expect(s).to.be_equal_to('Color.Red')
    end)

    it('should produce correct tostring for each member', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
        [3] = 'Blue',
      }
      expect(tostring(Color[1])).to.be_equal_to('Color.Red')
      expect(tostring(Color[2])).to.be_equal_to('Color.Green')
      expect(tostring(Color[3])).to.be_equal_to('Color.Blue')
    end)

    it('should work via the name lookup as well', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      expect(tostring(Color.Red)).to.be_equal_to('Color.Red')
    end)
  end)

  describe('__tointeger metamethod', function()
    it('should have a __tointeger metamethod on the enum value', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      local mt = getmetatable(Color[1])
      expect(mt.__tointeger).to_not.be_nil()
    end)

    it('should return the numeric value from __tointeger', function()
      local Color = enum 'Color' {
        [1] = 'Red',
        [2] = 'Green',
      }
      local mt = getmetatable(Color[1])
      expect(mt.__tointeger(Color[1])).to.be_equal_to(1)
      expect(mt.__tointeger(Color[2])).to.be_equal_to(2)
    end)
  end)

  describe('enum value fields', function()
    it('should store a reference back to the enum table', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      expect(Color[1].enum).to.be_equal_to(Color)
    end)

    it('should store the name field', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      expect(Color[1].name).to.be_equal_to('Red')
    end)

    it('should store the value field', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      expect(Color[1].value).to.be_equal_to(1)
    end)
  end)

  describe('non-contiguous indices', function()
    it('should support non-contiguous numeric indices', function()
      local Status = enum 'Status' {
        [0] = 'OK',
        [100] = 'Continue',
        [404] = 'NotFound',
      }
      expect(Status[0].name).to.be_equal_to('OK')
      expect(Status[100].name).to.be_equal_to('Continue')
      expect(Status[404].name).to.be_equal_to('NotFound')
    end)

    it('should support bidirectional lookup with non-contiguous indices', function()
      local Status = enum 'Status' {
        [0] = 'OK',
        [404] = 'NotFound',
      }
      expect(Status.OK.value).to.be_equal_to(0)
      expect(Status.NotFound.value).to.be_equal_to(404)
    end)
  end)

  describe('nil lookup for absent members', function()
    it('should return nil for an absent numeric index', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      expect(Color[99]).to.be_nil()
    end)

    it('should return nil for an absent string name', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      expect(Color['Purple']).to.be_nil()
    end)
  end)

  describe('multiple enums are independent', function()
    it('should not share members between different enums', function()
      local Color = enum 'Color' {
        [1] = 'Red',
      }
      local Fruit = enum 'Fruit' {
        [1] = 'Apple',
      }
      expect(Color[1].name).to.be_equal_to('Red')
      expect(Fruit[1].name).to.be_equal_to('Apple')
      expect(Color[1]).to_not.be_equal_to(Fruit[1])
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

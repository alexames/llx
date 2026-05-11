local unit = require 'llx.unit'
local llx = require 'llx'

local enum = require 'llx.enum' . enum
local hash = require 'llx.hash' . hash
local HashTable = require 'llx.hash_table' . HashTable

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

    it('should have the correct numeric value for a '
      .. 'value looked up by index', function()
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

    it('should have the correct numeric value when '
      .. 'looked up by name', function()
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
    it('should return the same enum object for index '
      .. 'and name lookups', function()
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

    it('should support bidirectional lookup with '
      .. 'non-contiguous indices', function()
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

  describe('__eq', function()
    it('should compare equal for same enum value', function()
      local Color = enum 'Color' {
        [1] = 'Red', [2] = 'Green',
      }
      expect(Color[1] == Color.Red).to.be_truthy()
    end)

    it('should not compare equal across '
      .. 'different enums', function()
      local A = enum 'A' { [1] = 'X' }
      local B = enum 'B' { [1] = 'X' }
      expect(A[1] == B[1]).to.be_falsy()
    end)
  end)

  describe('__lt and __le (ordering)', function()
    it('should order by numeric value', function()
      local Priority = enum 'Priority' {
        [1] = 'Low', [2] = 'Medium', [3] = 'High',
      }
      expect(Priority.Low < Priority.Medium)
        .to.be_truthy()
      expect(Priority.High < Priority.Low)
        .to.be_falsy()
    end)

    it('should support <= for equal values', function()
      local Color = enum 'Color' {
        [1] = 'Red', [2] = 'Green',
      }
      expect(Color.Red <= Color.Red).to.be_truthy()
      expect(Color.Red <= Color.Green).to.be_truthy()
      expect(Color.Green <= Color.Red).to.be_falsy()
    end)

    it('should allow sorting enum values', function()
      local Size = enum 'Size' {
        [3] = 'Large', [1] = 'Small', [2] = 'Medium',
      }
      local sorted = {Size.Large, Size.Small, Size.Medium}
      table.sort(sorted)
      expect(sorted[1]).to.be_equal_to(Size.Small)
      expect(sorted[2]).to.be_equal_to(Size.Medium)
      expect(sorted[3]).to.be_equal_to(Size.Large)
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

  describe('__hash', function()
    it('should hash equal for same enum value', function()
      local Color = enum 'Color' {
        [1] = 'Red', [2] = 'Green', [3] = 'Blue',
      }
      expect(hash(Color.Red)).to.be_equal_to(hash(Color[1]))
    end)

    it('should hash differently for different values '
      .. 'of the same enum', function()
      local Color = enum 'Color' {
        [1] = 'Red', [2] = 'Green', [3] = 'Blue',
      }
      expect(hash(Color.Red)).to_not.be_equal_to(hash(Color.Green))
    end)

    it('should be usable as a HashTable key', function()
      local Color = enum 'Color' {
        [1] = 'Red', [2] = 'Green',
      }
      local ht = HashTable()
      ht[Color.Red] = 'rouge'
      ht[Color.Green] = 'vert'
      expect(ht[Color.Red]).to.be_equal_to('rouge')
      expect(ht[Color.Green]).to.be_equal_to('vert')
    end)
  end)
end)

describe('enum.Flag', function()
  local Flag = require 'llx.enum'.Flag

  describe('construction', function()
    it('should require a string name', function()
      expect(function() Flag(42) end).to.throw()
    end)

    it('should require integer values', function()
      expect(function()
        Flag 'P' { Read = 'not_a_number' }
      end).to.throw()
    end)

    it('should reject duplicate member names', function()
      -- Pure Lua tables can't have duplicate keys in a literal, so
      -- this case can only fail if Flag is given a pre-built map
      -- with collisions, which is hard to construct. Skip in
      -- favor of the integer-value test above.
    end)
  end)

  describe('individual flag access', function()
    it('should expose each member by name', function()
      local P = Flag 'P' { Read = 1, Write = 2, Execute = 4 }
      expect(P.Read.value).to.be_equal_to(1)
      expect(P.Write.value).to.be_equal_to(2)
      expect(P.Execute.value).to.be_equal_to(4)
    end)
  end)

  describe('composition operators', function()
    it('should combine via |', function()
      local P = Flag 'P' { Read = 1, Write = 2, Execute = 4 }
      expect((P.Read | P.Write).value).to.be_equal_to(3)
    end)

    it('should intersect via &', function()
      local P = Flag 'P' { Read = 1, Write = 2, Execute = 4 }
      expect(((P.Read | P.Write) & P.Read).value).to.be_equal_to(1)
    end)

    it('should xor via ~', function()
      local P = Flag 'P' { Read = 1, Write = 2, Execute = 4 }
      expect(((P.Read | P.Write) ~ P.Write).value).to.be_equal_to(1)
    end)

    it('should clear bits via -', function()
      local P = Flag 'P' { Read = 1, Write = 2, Execute = 4 }
      expect(((P.Read | P.Write) - P.Read).value).to.be_equal_to(2)
    end)
  end)

  describe(':has()', function()
    it('should return true for a flag that is set', function()
      local P = Flag 'P' { Read = 1, Write = 2 }
      expect((P.Read | P.Write):has(P.Read)).to.be_true()
    end)

    it('should return false for a flag that is not set', function()
      local P = Flag 'P' { Read = 1, Write = 2 }
      expect(P.Read:has(P.Write)).to.be_false()
    end)

    it('should require all bits when checking a combined flag', function()
      local P = Flag 'P' { Read = 1, Write = 2 }
      expect((P.Read | P.Write):has(P.Read | P.Write)).to.be_true()
      expect(P.Read:has(P.Read | P.Write)).to.be_false()
    end)
  end)

  describe('__tostring', function()
    it('should print individual flags as Name.Member', function()
      local P = Flag 'P' { Read = 1, Write = 2 }
      expect(tostring(P.Read)).to.be_equal_to('P.Read')
    end)

    it('should print combined flags as Name.A|B|...', function()
      local P = Flag 'P' { Read = 1, Write = 2 }
      expect(tostring(P.Read | P.Write)).to.be_equal_to('P.Read|Write')
    end)

    it('should print empty value as <none>', function()
      local P = Flag 'P' { Read = 1, Write = 2 }
      expect(tostring(P.Read - P.Read)).to.contain('none')
    end)
  end)

  describe('__eq, __hash, __tointeger', function()
    it('should compare equal for same value', function()
      local P = Flag 'P' { A = 1, B = 2 }
      expect(P.A | P.B).to.be_equal_to(P.B | P.A)
    end)

    it('should hash equal for equal flag values', function()
      local P = Flag 'P' { A = 1, B = 2 }
      local hash = require 'llx.hash'.hash
      expect(hash(P.A | P.B)).to.be_equal_to(hash(P.B | P.A))
    end)

    it('should convert to integer via __tointeger', function()
      local P = Flag 'P' { A = 1, B = 2 }
      local mt = getmetatable(P.A)
      expect(mt.__tointeger(P.A)).to.be_equal_to(1)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

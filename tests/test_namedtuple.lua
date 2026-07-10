local unit = require 'llx.unit'
local llx = require 'llx'
local namedtuple = require 'llx.namedtuple' . namedtuple
local hash = require 'llx.hash' . hash
local HashTable = require 'llx.hash_table' . HashTable

_ENV = unit.create_test_env(_ENV)

describe('namedtuple', function()
  describe('factory validation', function()
    it('should require a string name', function()
      expect(function() namedtuple(nil, {'x'}) end).to.throw()
      expect(function() namedtuple(42, {'x'}) end).to.throw()
    end)

    it('should require a fields table', function()
      expect(function() namedtuple('P', nil) end).to.throw()
    end)

    it('should reject non-string field names', function()
      expect(function() namedtuple('P', {1, 2}) end).to.throw()
    end)

    it('should reject duplicate field names', function()
      expect(function() namedtuple('P', {'x', 'x'}) end).to.throw()
    end)
  end)

  describe('construction', function()
    it('should create instances with positional values', function()
      local Point = namedtuple('Point', {'x', 'y'})
      local p = Point(3, 4)
      expect(p.x).to.be_equal_to(3)
      expect(p.y).to.be_equal_to(4)
    end)

    it('should error on too few arguments', function()
      local Point = namedtuple('Point', {'x', 'y'})
      expect(function() Point(1) end).to.throw()
    end)

    it('should error on too many arguments', function()
      local Point = namedtuple('Point', {'x', 'y'})
      expect(function() Point(1, 2, 3) end).to.throw()
    end)

    it('should accept zero fields', function()
      local Empty = namedtuple('Empty', {})
      local e = Empty()
      expect(#e).to.be_equal_to(0)
    end)
  end)

  describe('access', function()
    it('should support positional indexing', function()
      local Point = namedtuple('Point', {'x', 'y'})
      local p = Point(10, 20)
      expect(p[1]).to.be_equal_to(10)
      expect(p[2]).to.be_equal_to(20)
    end)

    it('should support named access', function()
      local Person = namedtuple('Person', {'name', 'age'})
      local p = Person('Alice', 30)
      expect(p.name).to.be_equal_to('Alice')
      expect(p.age).to.be_equal_to(30)
    end)

    it('should be immutable', function()
      local Point = namedtuple('Point', {'x', 'y'})
      local p = Point(1, 2)
      -- Python: named-field assignment -> AttributeError,
      -- positional -> TypeError.
      local ok_attr, err_attr = pcall(function() p.x = 99 end)
      expect(ok_attr).to.be_false()
      expect(tostring(err_attr)).to.contain('AttributeError')
      local ok_item, err_item = pcall(function() p[1] = 99 end)
      expect(ok_item).to.be_false()
      expect(tostring(err_item)).to.contain('TypeError')
    end)

    it('should return field list via :fields()', function()
      local Point = namedtuple('Point', {'x', 'y'})
      local p = Point(1, 2)
      local f = p:fields()
      expect(f[1]).to.be_equal_to('x')
      expect(f[2]).to.be_equal_to('y')
    end)

    it('should convert to plain table via :as_table()', function()
      local Point = namedtuple('Point', {'x', 'y'})
      local p = Point(7, 8)
      local t = p:as_table()
      expect(t.x).to.be_equal_to(7)
      expect(t.y).to.be_equal_to(8)
    end)
  end)

  describe('__len', function()
    it('should return field count', function()
      local Point = namedtuple('Point', {'x', 'y', 'z'})
      expect(#Point(1, 2, 3)).to.be_equal_to(3)
    end)
  end)

  describe('__eq, __hash, __tostring', function()
    it('should compare equal by value', function()
      local Point = namedtuple('Point', {'x', 'y'})
      expect(Point(1, 2) == Point(1, 2)).to.be_true()
    end)

    it('should compare unequal for different values', function()
      local Point = namedtuple('Point', {'x', 'y'})
      expect(Point(1, 2) == Point(1, 3)).to.be_false()
    end)

    it('should hash equal for equal instances', function()
      local Point = namedtuple('Point', {'x', 'y'})
      expect(hash(Point(1, 2))).to.be_equal_to(hash(Point(1, 2)))
    end)

    it('should be usable as a HashTable key', function()
      local Point = namedtuple('Point', {'x', 'y'})
      local ht = HashTable()
      ht[Point(1, 2)] = 'origin-ish'
      expect(ht[Point(1, 2)]).to.be_equal_to('origin-ish')
    end)

    it('should produce a Name(field=v, ...) tostring', function()
      local Point = namedtuple('Point', {'x', 'y'})
      expect(tostring(Point(3, 4))).to.be_equal_to('Point(x=3, y=4)')
    end)
  end)

  describe('iteration', function()
    it('should iterate fields with ipairs via numeric indexing', function()
      local Triple = namedtuple('Triple', {'a', 'b', 'c'})
      local t = Triple(10, 20, 30)
      local sum = 0
      for i = 1, #t do sum = sum + t[i] end
      expect(sum).to.be_equal_to(60)
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end

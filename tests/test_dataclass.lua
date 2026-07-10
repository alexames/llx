local unit = require 'llx.unit'
local llx = require 'llx'
local dataclass = require 'llx.dataclass'.dataclass

local hash = require 'llx.hash'.hash
local HashTable = require 'llx.hash_table'.HashTable

_ENV = unit.create_test_env(_ENV)

describe('dataclass', function()
  describe('factory validation', function()
    it('should require a string name', function()
      expect(function() dataclass(42, {{name='x'}}) end).to.throw()
    end)

    it('should require a fields table', function()
      expect(function() dataclass('P', nil) end).to.throw()
    end)

    it('should require each field to have a name', function()
      expect(function()
        dataclass('P', {{type=llx.Integer}})
      end).to.throw()
    end)

    it('should reject duplicate field names', function()
      expect(function()
        dataclass('P', {{name='x'}, {name='x'}})
      end).to.throw()
    end)
  end)

  describe('positional construction', function()
    it('should populate fields from positional args', function()
      local Point = dataclass('Point', {
        {name='x', type=llx.Integer},
        {name='y', type=llx.Integer},
      })
      local p = Point(3, 4)
      expect(p.x).to.be_equal_to(3)
      expect(p.y).to.be_equal_to(4)
    end)

    it('should accept defaults for missing trailing args', function()
      local Point = dataclass('Point', {
        {name='x', type=llx.Integer},
        {name='y', type=llx.Integer, default=99},
      })
      local p = Point(3)
      expect(p.x).to.be_equal_to(3)
      expect(p.y).to.be_equal_to(99)
    end)

    it('should error on missing required field', function()
      local Point = dataclass('Point', {
        {name='x', type=llx.Integer},
        {name='y', type=llx.Integer},  -- no default
      })
      expect(function() Point(3) end).to.throw()
    end)
  end)

  describe('keyword construction', function()
    it('should populate fields from a keyword table', function()
      local Point = dataclass('Point', {
        {name='x', type=llx.Integer},
        {name='y', type=llx.Integer},
      })
      local p = Point{x=3, y=4}
      expect(p.x).to.be_equal_to(3)
      expect(p.y).to.be_equal_to(4)
    end)

    it('should fill defaults for missing fields', function()
      local Point = dataclass('Point', {
        {name='x', type=llx.Integer, default=0},
        {name='y', type=llx.Integer, default=0},
      })
      local p = Point{x=5}
      expect(p.x).to.be_equal_to(5)
      expect(p.y).to.be_equal_to(0)
    end)

    it('should error on missing required field via kwargs', function()
      local Point = dataclass('Point', {
        {name='x', type=llx.Integer},
        {name='y', type=llx.Integer},
      })
      expect(function() Point{x=3} end).to.throw()
    end)
  end)

  describe('mutability (default)', function()
    it('should allow direct field assignment', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      local p = Point(1, 2)
      p.x = 99
      expect(p.x).to.be_equal_to(99)
    end)
  end)

  describe('immutable option', function()
    it('should reject assignment to fields', function()
      local Point = dataclass('Point',
        {{name='x'}, {name='y'}},
        {immutable=true})
      local p = Point(1, 2)
      -- Python's frozen dataclass raises AttributeError on field assignment.
      local ok, err = pcall(function() p.x = 99 end)
      expect(ok).to.be_false()
      expect(tostring(err)).to.contain('AttributeError')
    end)

    it('should still read fields correctly', function()
      local Point = dataclass('Point',
        {{name='x'}, {name='y'}},
        {immutable=true})
      local p = Point(1, 2)
      expect(p.x).to.be_equal_to(1)
      expect(p.y).to.be_equal_to(2)
    end)

    it('should reject assignment of new keys too', function()
      local Point = dataclass('Point',
        {{name='x'}, {name='y'}},
        {immutable=true})
      local p = Point(1, 2)
      expect(function() p.z = 99 end).to.throw()
    end)
  end)

  describe('__eq, __hash, __tostring', function()
    it('should compare equal for same field values', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      expect(Point(1, 2) == Point(1, 2)).to.be_true()
    end)

    it('should compare unequal for different field values', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      expect(Point(1, 2) == Point(1, 3)).to.be_false()
    end)

    it('should hash equal instances to the same value', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      expect(hash(Point(1, 2))).to.be_equal_to(hash(Point(1, 2)))
    end)

    it('should be usable as a HashTable key', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      local ht = HashTable()
      ht[Point(1, 2)] = 'origin-ish'
      expect(ht[Point(1, 2)]).to.be_equal_to('origin-ish')
    end)

    it('should tostring as Name(field=value, ...)', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      expect(tostring(Point(3, 4))).to.be_equal_to('Point(x=3, y=4)')
    end)
  end)

  describe('introspection', function()
    it(':fields returns the declared field names in order', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}, {name='z'}})
      local p = Point(1, 2, 3)
      local f = p:fields()
      expect(f[1]).to.be_equal_to('x')
      expect(f[3]).to.be_equal_to('z')
    end)

    it(':as_table returns a plain map', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      local p = Point(7, 8)
      local t = p:as_table()
      expect(t.x).to.be_equal_to(7)
      expect(t.y).to.be_equal_to(8)
    end)
  end)

  describe('replace', function()
    it('should produce a new instance with one field overridden', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      local p = Point(1, 2)
      local q = p:replace{x = 99}
      expect(q.x).to.be_equal_to(99)
      expect(q.y).to.be_equal_to(2)
      expect(p.x).to.be_equal_to(1)  -- original unchanged
    end)

    it('should support immutable dataclasses', function()
      local Point = dataclass('Point',
        {{name='x'}, {name='y'}},
        {immutable=true})
      local p = Point(1, 2)
      local q = p:replace{x=99}
      expect(q.x).to.be_equal_to(99)
    end)

    it('should reject unknown field overrides', function()
      local Point = dataclass('Point', {{name='x'}, {name='y'}})
      expect(function()
        Point(1, 2):replace{nonexistent=1}
      end).to.throw()
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0)
end

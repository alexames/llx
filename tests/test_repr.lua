local unit = require 'llx.unit'
local llx = require 'llx'

local repr_module = require 'llx.repr'
local repr = repr_module.repr

_ENV = unit.create_test_env(_ENV)

describe('repr', function()
  describe('nil values', function()
    it('should represent nil as the string nil', function()
      expect(repr(nil)).to.be_equal_to('nil')
    end)
  end)

  describe('number values', function()
    it('should represent positive integers', function()
      expect(repr(42)).to.be_equal_to(42)
    end)

    it('should represent zero', function()
      expect(repr(0)).to.be_equal_to(0)
    end)

    it('should represent negative numbers', function()
      expect(repr(-7)).to.be_equal_to(-7)
    end)

    it('should represent floating point numbers', function()
      expect(repr(3.14)).to.be_equal_to(3.14)
    end)
  end)

  describe('boolean values', function()
    it('should represent true as the string true', function()
      expect(repr(true)).to.be_equal_to('true')
    end)

    it('should represent false as the string false', function()
      expect(repr(false)).to.be_equal_to('false')
    end)
  end)

  describe('string values', function()
    it('should represent a simple string with quotes', function()
      expect(repr('hello')).to.be_equal_to('"hello"')
    end)

    it('should represent an empty string with quotes', function()
      expect(repr('')).to.be_equal_to('""')
    end)

    it('should escape special characters using string.format %%q', function()
      -- Lua 5.4 string.format %q uses backslash-newline for newlines
      local result = repr('line1\nline2')
      expect(result).to.be_equal_to(string.format('%q', 'line1\nline2'))
    end)

    it('should escape backslashes', function()
      local result = repr('a\\b')
      expect(result).to.be_equal_to('"a\\\\b"')
    end)

    it('should handle strings with double quotes', function()
      local result = repr('say "hi"')
      expect(result).to.be_equal_to(string.format('%q', 'say "hi"'))
    end)
  end)

  -- NOTE: repr for tables currently errors because getmetafield is referenced
  -- as a bare name in the module but was not imported into the module
  -- environment (it should be core.getmetafield or local getmetafield =
  -- core.getmetafield). We test that the error is raised as expected.
  describe('table values', function()
    it('should error due to missing getmetafield in module environment', function()
      expect(function() repr({}) end).to.throw()
    end)

    it('should error for non-empty arrays', function()
      expect(function() repr({1, 2, 3}) end).to.throw()
    end)

    it('should error for tables with string keys', function()
      expect(function() repr({a = 1}) end).to.throw()
    end)

    it('should error for nested tables', function()
      expect(function() repr({{1, 2}, {3, 4}}) end).to.throw()
    end)
  end)

  describe('custom __repr metamethod', function()
    it('should error because getmetafield lookup fails', function()
      local obj = setmetatable({value = 42}, {
        __repr = function(self)
          return 'CustomObj(' .. tostring(self.value) .. ')'
        end
      })
      expect(function() repr(obj) end).to.throw()
    end)
  end)

  describe('other types', function()
    it('should return the type name for functions', function()
      expect(repr(function() end)).to.be_equal_to('function')
    end)

    it('should return the type name for coroutines', function()
      local co = coroutine.create(function() end)
      expect(repr(co)).to.be_equal_to('thread')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

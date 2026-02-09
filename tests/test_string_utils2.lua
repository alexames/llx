-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.string'
require 'llx.types.list'

_ENV = unit.create_test_env(_ENV)

describe('string utilities (tier 2)', function()
  describe('pad_left', function()
    it('should pad a string to the given width', function()
      expect(string.pad_left('hi', 5)).to.be_equal_to('   hi')
    end)

    it('should use a custom fill character', function()
      expect(string.pad_left('42', 5, '0')).to.be_equal_to('00042')
    end)

    it('should return original string if already at width', function()
      expect(string.pad_left('hello', 5)).to.be_equal_to('hello')
    end)

    it('should return original string if longer than width', function()
      expect(string.pad_left('hello', 3)).to.be_equal_to('hello')
    end)
  end)

  describe('pad_right', function()
    it('should pad a string to the given width', function()
      expect(string.pad_right('hi', 5)).to.be_equal_to('hi   ')
    end)

    it('should use a custom fill character', function()
      expect(string.pad_right('hi', 5, '.')).to.be_equal_to('hi...')
    end)

    it('should return original string if already at width', function()
      expect(string.pad_right('hello', 5)).to.be_equal_to('hello')
    end)
  end)

  describe('center', function()
    it('should center a string within the given width', function()
      expect(string.center('hi', 6)).to.be_equal_to('  hi  ')
    end)

    it('should favor right-padding when centering is uneven', function()
      expect(string.center('hi', 5)).to.be_equal_to(' hi  ')
    end)

    it('should use a custom fill character', function()
      expect(string.center('hi', 6, '-')).to.be_equal_to('--hi--')
    end)

    it('should return original string if already at width', function()
      expect(string.center('hello', 5)).to.be_equal_to('hello')
    end)
  end)

  describe('capitalize', function()
    it('should capitalize the first character', function()
      expect(string.capitalize('hello')).to.be_equal_to('Hello')
    end)

    it('should handle a single character', function()
      expect(string.capitalize('a')).to.be_equal_to('A')
    end)

    it('should return empty string for empty input', function()
      expect(string.capitalize('')).to.be_equal_to('')
    end)

    it('should not change already capitalized strings', function()
      expect(string.capitalize('Hello')).to.be_equal_to('Hello')
    end)
  end)

  describe('words', function()
    it('should split a string into words', function()
      local result = string.words('hello world foo')
      expect(result).to.be_equal_to(llx.List{'hello', 'world', 'foo'})
    end)

    it('should handle multiple spaces', function()
      local result = string.words('  hello   world  ')
      expect(result).to.be_equal_to(llx.List{'hello', 'world'})
    end)

    it('should return empty list for empty string', function()
      local result = string.words('')
      expect(#result).to.be_equal_to(0)
    end)
  end)

  describe('lines', function()
    it('should split a string into lines', function()
      local result = string.lines('a\nb\nc')
      expect(result).to.be_equal_to(llx.List{'a', 'b', 'c'})
    end)

    it('should handle trailing newline', function()
      local result = string.lines('a\nb\n')
      expect(result).to.be_equal_to(llx.List{'a', 'b', ''})
    end)

    it('should handle single line with no newline', function()
      local result = string.lines('hello')
      expect(result).to.be_equal_to(llx.List{'hello'})
    end)
  end)

  describe('count', function()
    it('should count occurrences of a substring', function()
      expect(string.count('abcabc', 'abc')).to.be_equal_to(2)
    end)

    it('should count non-overlapping occurrences', function()
      expect(string.count('aaa', 'aa')).to.be_equal_to(1)
    end)

    it('should return 0 when substring is not found', function()
      expect(string.count('hello', 'xyz')).to.be_equal_to(0)
    end)

    it('should handle pattern special characters as literal text', function()
      expect(string.count('a.b.c', '.')).to.be_equal_to(2)
    end)
  end)

  describe('truncate', function()
    it('should truncate long strings with ellipsis', function()
      expect(string.truncate('hello world', 8)).to.be_equal_to('hello...')
    end)

    it('should return original string if within limit', function()
      expect(string.truncate('hi', 10)).to.be_equal_to('hi')
    end)

    it('should use a custom suffix', function()
      expect(string.truncate('hello world', 8, '--')).to.be_equal_to('hello --')
    end)

    it('should handle exact length', function()
      expect(string.truncate('hello', 5)).to.be_equal_to('hello')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

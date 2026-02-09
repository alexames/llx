-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.string'
require 'llx.types.list'

_ENV = unit.create_test_env(_ENV)

describe('string utilities', function()
  describe('split', function()
    it('should split by a single-character delimiter', function()
      local result = string.split('a,b,c', ',')
      expect(result).to.be_equal_to(llx.List{'a', 'b', 'c'})
    end)

    it('should split by a multi-character delimiter', function()
      local result = string.split('a::b::c', '::')
      expect(result).to.be_equal_to(llx.List{'a', 'b', 'c'})
    end)

    it('should return the whole string when delimiter is not found', function()
      local result = string.split('hello', ',')
      expect(result).to.be_equal_to(llx.List{'hello'})
    end)

    it('should handle empty parts', function()
      local result = string.split(',a,,b,', ',')
      expect(result).to.be_equal_to(llx.List{'', 'a', '', 'b', ''})
    end)

    it('should split on whitespace by default', function()
      local result = string.split('hello world')
      expect(result).to.be_equal_to(llx.List{'hello', 'world'})
    end)

    it('should handle empty string', function()
      local result = string.split('', ',')
      expect(result).to.be_equal_to(llx.List{''})
    end)
  end)

  describe('trim', function()
    it('should remove leading and trailing whitespace', function()
      expect(string.trim('  hello  ')).to.be_equal_to('hello')
    end)

    it('should remove tabs and newlines', function()
      expect(string.trim('\t\nhello\n\t')).to.be_equal_to('hello')
    end)

    it('should not modify interior whitespace', function()
      expect(string.trim('  hello world  ')).to.be_equal_to('hello world')
    end)

    it('should return empty string for whitespace-only input', function()
      expect(string.trim('   ')).to.be_equal_to('')
    end)

    it('should return string unchanged if no whitespace to trim', function()
      expect(string.trim('hello')).to.be_equal_to('hello')
    end)
  end)

  describe('ltrim', function()
    it('should remove leading whitespace only', function()
      expect(string.ltrim('  hello  ')).to.be_equal_to('hello  ')
    end)
  end)

  describe('rtrim', function()
    it('should remove trailing whitespace only', function()
      expect(string.rtrim('  hello  ')).to.be_equal_to('  hello')
    end)
  end)

  describe('contains', function()
    it('should return true when substring is present', function()
      expect(string.contains('hello world', 'world')).to.be_true()
    end)

    it('should return false when substring is absent', function()
      expect(string.contains('hello world', 'xyz')).to.be_false()
    end)

    it('should return true for empty substring', function()
      expect(string.contains('hello', '')).to.be_true()
    end)

    it('should perform plain text search, not pattern matching', function()
      expect(string.contains('file.lua', '.')).to.be_true()
      expect(string.contains('file', '.')).to.be_false()
    end)
  end)

  describe('replace', function()
    it('should replace all occurrences of a plain substring', function()
      expect(string.replace('aabbcc', 'bb', 'XX')).to.be_equal_to('aaXXcc')
    end)

    it('should replace multiple occurrences', function()
      expect(string.replace('abab', 'ab', 'X')).to.be_equal_to('XX')
    end)

    it('should return original string when target is not found', function()
      expect(string.replace('hello', 'xyz', 'X')).to.be_equal_to('hello')
    end)

    it('should handle pattern special characters as literal text', function()
      expect(string.replace('a.b.c', '.', '-')).to.be_equal_to('a-b-c')
    end)

    it('should support limiting number of replacements', function()
      expect(string.replace('aaaa', 'a', 'b', 2)).to.be_equal_to('bbaa')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

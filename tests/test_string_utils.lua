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

  describe('snake_case', function()
    it('should convert camelCase', function()
      expect(('camelCase'):snake_case()).to.be_equal_to('camel_case')
    end)

    it('should convert PascalCase', function()
      expect(('PascalCase'):snake_case()).to.be_equal_to('pascal_case')
    end)

    it('should convert kebab-case', function()
      expect(('kebab-case'):snake_case()).to.be_equal_to('kebab_case')
    end)

    it('should convert spaces', function()
      expect(('hello world'):snake_case()).to.be_equal_to('hello_world')
    end)

    it('should handle consecutive uppercase', function()
      expect(('HTMLParser'):snake_case()).to.be_equal_to('html_parser')
    end)

    it('should handle already snake_case', function()
      expect(('already_snake'):snake_case()).to.be_equal_to('already_snake')
    end)
  end)

  describe('camel_case', function()
    it('should convert snake_case', function()
      expect(('hello_world'):camel_case()).to.be_equal_to('helloWorld')
    end)

    it('should convert kebab-case', function()
      expect(('hello-world'):camel_case()).to.be_equal_to('helloWorld')
    end)

    it('should convert spaces', function()
      expect(('hello world'):camel_case()).to.be_equal_to('helloWorld')
    end)

    it('should handle already camelCase', function()
      expect(('helloWorld'):camel_case()).to.be_equal_to('helloWorld')
    end)
  end)

  describe('kebab_case', function()
    it('should convert camelCase', function()
      expect(('camelCase'):kebab_case()).to.be_equal_to('camel-case')
    end)

    it('should convert snake_case', function()
      expect(('snake_case'):kebab_case()).to.be_equal_to('snake-case')
    end)

    it('should convert spaces', function()
      expect(('hello world'):kebab_case()).to.be_equal_to('hello-world')
    end)
  end)

  describe('escape_pattern', function()
    it('should escape dots', function()
      expect(('a.b'):escape_pattern()).to.be_equal_to('a%.b')
    end)

    it('should escape all special chars', function()
      expect(('()%.+*?[]^$'):escape_pattern()).to.be_equal_to('%(%)%%%.%+%*%?%[%]%^%$')
    end)

    it('should leave normal chars unchanged', function()
      expect(('hello'):escape_pattern()).to.be_equal_to('hello')
    end)
  end)

  describe('is_alpha', function()
    it('should return true for alphabetic strings', function()
      expect(('hello'):is_alpha()).to.be_equal_to(true)
    end)

    it('should return false for strings with digits', function()
      expect(('hello1'):is_alpha()).to.be_equal_to(false)
    end)

    it('should return false for empty string', function()
      expect((''):is_alpha()).to.be_equal_to(false)
    end)
  end)

  describe('is_digit', function()
    it('should return true for digit strings', function()
      expect(('12345'):is_digit()).to.be_equal_to(true)
    end)

    it('should return false for alpha strings', function()
      expect(('hello'):is_digit()).to.be_equal_to(false)
    end)
  end)

  describe('is_alnum', function()
    it('should return true for alphanumeric strings', function()
      expect(('hello123'):is_alnum()).to.be_equal_to(true)
    end)

    it('should return false for strings with special chars', function()
      expect(('hello!'):is_alnum()).to.be_equal_to(false)
    end)
  end)

  describe('is_space', function()
    it('should return true for whitespace strings', function()
      expect(('  \t\n'):is_space()).to.be_equal_to(true)
    end)

    it('should return false for non-whitespace', function()
      expect(('hello'):is_space()).to.be_equal_to(false)
    end)
  end)

  describe('template', function()
    it('should substitute named variables', function()
      expect(('Hello, ${name}!'):template({name = 'World'})).to.be_equal_to('Hello, World!')
    end)

    it('should substitute multiple variables', function()
      expect(('${a} + ${b} = ${c}'):template({a = '1', b = '2', c = '3'})).to.be_equal_to('1 + 2 = 3')
    end)

    it('should leave unmatched placeholders unchanged', function()
      expect(('${x} and ${y}'):template({x = 'found'})).to.be_equal_to('found and ${y}')
    end)

    it('should handle numeric values', function()
      expect(('count: ${n}'):template({n = 42})).to.be_equal_to('count: 42')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

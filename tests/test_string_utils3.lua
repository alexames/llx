-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.string'

_ENV = unit.create_test_env(_ENV)

describe('string utilities (tier 3)', function()
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

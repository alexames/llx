local unit = require 'llx.unit'
local llx = require 'llx'

local tostringf_module = require 'llx.tostringf'
local tostringf = tostringf_module.tostringf
local StringFormatter = tostringf_module.StringFormatter
local styles = tostringf_module.styles
local TypeVerbosity = tostringf_module.TypeVerbosity

_ENV = unit.create_test_env(_ENV)

describe('tostringf', function()
  describe('nil values', function()
    it('should format nil as the string nil', function()
      expect(tostringf(nil, styles.minimal)).to.be_equal_to('nil')
    end)
  end)

  describe('boolean values', function()
    it('should format true as the string true', function()
      expect(tostringf(true, styles.minimal)).to.be_equal_to('true')
    end)

    it('should format false as the string false', function()
      expect(tostringf(false, styles.minimal)).to.be_equal_to('false')
    end)
  end)

  describe('number values', function()
    it('should format a positive integer', function()
      expect(tostringf(42, styles.minimal)).to.be_equal_to('42')
    end)

    it('should format zero', function()
      expect(tostringf(0, styles.minimal)).to.be_equal_to('0')
    end)

    it('should format a negative number', function()
      expect(tostringf(-7, styles.minimal)).to.be_equal_to('-7')
    end)

    it('should format a floating point number', function()
      expect(tostringf(3.14, styles.minimal)).to.be_equal_to('3.14')
    end)
  end)

  describe('string values', function()
    it('should wrap a simple string in single quotes', function()
      expect(tostringf('hello', styles.minimal)).to.be_equal_to("'hello'")
    end)

    it('should wrap an empty string in single quotes', function()
      expect(tostringf('', styles.minimal)).to.be_equal_to("''")
    end)

    it('should use double quotes when string contains single quotes', function()
      expect(tostringf("it's", styles.minimal)).to.be_equal_to('"it\'s"')
    end)

    it('should use single quotes when string contains double quotes', function()
      expect(tostringf('say "hi"', styles.minimal)).to.be_equal_to("'say \"hi\"'")
    end)

    it('should use long bracket notation when string contains both quote types', function()
      local value = [[it's a "test"]]
      local result = tostringf(value, styles.minimal)
      -- Should use long brackets like [=[...]=] or similar
      expect(result:sub(1, 1)).to.be_equal_to('[')
      expect(result:sub(-1, -1)).to.be_equal_to(']')
      -- Verify the value is embedded inside
      expect(result:find(value, 1, true)).to_not.be_nil()
    end)
  end)

  describe('table values with minimal style', function()
    it('should format an empty table', function()
      expect(tostringf({}, styles.minimal)).to.be_equal_to('{}')
    end)

    it('should format a list of numbers', function()
      expect(tostringf({1, 2, 3}, styles.minimal)).to.be_equal_to('{1,2,3}')
    end)

    it('should format a single element list', function()
      expect(tostringf({42}, styles.minimal)).to.be_equal_to('{42}')
    end)

    it('should format a list of strings', function()
      expect(tostringf({'a', 'b'}, styles.minimal)).to.be_equal_to("{\'a\',\'b\'}")
    end)

    it('should format a list of booleans', function()
      expect(tostringf({true, false}, styles.minimal)).to.be_equal_to('{true,false}')
    end)

    it('should format a table with string keys', function()
      -- Single key table for deterministic ordering
      local result = tostringf({x=1}, styles.minimal)
      expect(result).to.be_equal_to('{x=1}')
    end)
  end)

  describe('table values with abbrev style', function()
    it('should format a list with spaces after delimiter', function()
      expect(tostringf({1, 2, 3}, styles.abbrev)).to.be_equal_to('{1, 2, 3}')
    end)

    it('should format a table with string key', function()
      local result = tostringf({x=1}, styles.abbrev)
      expect(result).to.be_equal_to('{x=1}')
    end)
  end)

  describe('table values with struct style', function()
    it('should format a list with newlines and indentation', function()
      local result = tostringf({1, 2}, styles.struct)
      local expected = '{\n  1,\n  2,\n}'
      expect(result).to.be_equal_to(expected)
    end)

    it('should format a table with string key with spaces around assignment', function()
      local result = tostringf({x=1}, styles.struct)
      local expected = '{\n  x = 1,\n}'
      expect(result).to.be_equal_to(expected)
    end)
  end)

  describe('table key formatting', function()
    it('should use bracket notation for numeric keys in non-list tables', function()
      -- A table that is not a pure list (mixed keys)
      local t = {[1] = 'a', x = 'b'}
      local result = tostringf(t, styles.minimal)
      -- Both [1]='a' and x='b' should appear somewhere
      expect(result:find('%[1%]')).to_not.be_nil()
      expect(result:find('x=')).to_not.be_nil()
    end)

    it('should bracket-quote keys that are Lua keywords', function()
      local result = tostringf({['end'] = 1}, styles.minimal)
      expect(result).to.be_equal_to('{[\'end\']=1}')
    end)

    it('should use plain names for valid identifier keys', function()
      local result = tostringf({foo = 1}, styles.minimal)
      expect(result).to.be_equal_to('{foo=1}')
    end)
  end)

  describe('__tostringf metamethod', function()
    it('should use __tostringf when present on value', function()
      local obj = setmetatable({}, {
        __tostringf = function(self, formatter)
          formatter:insert('custom_output')
        end
      })
      local result = tostringf(obj, styles.minimal)
      expect(result).to.be_equal_to('custom_output')
    end)

    it('should pass the formatter to __tostringf', function()
      local received_formatter = nil
      local obj = setmetatable({}, {
        __tostringf = function(self, formatter)
          received_formatter = formatter
          formatter:insert('ok')
        end
      })
      tostringf(obj, styles.minimal)
      expect(received_formatter).to_not.be_nil()
    end)
  end)

  describe('nested tables', function()
    it('should format nested tables with minimal style', function()
      local result = tostringf({{1, 2}, {3, 4}}, styles.minimal)
      expect(result).to.be_equal_to('{{1,2},{3,4}}')
    end)

    it('should format nested tables with abbrev style', function()
      local result = tostringf({{1, 2}, {3, 4}}, styles.abbrev)
      expect(result).to.be_equal_to('{{1, 2}, {3, 4}}')
    end)
  end)
end)

describe('StringFormatter', function()
  describe('insert and concat', function()
    it('should accumulate inserted values', function()
      local f = StringFormatter(styles.minimal)
      f:insert('hello')
      f:insert(' ')
      f:insert('world')
      expect(f:concat()).to.be_equal_to('hello world')
    end)
  end)

  describe('clone', function()
    it('should share the same buffer as the original', function()
      local f = StringFormatter(styles.minimal)
      f:insert('a')
      local g = f:clone(styles.abbrev)
      g:insert('b')
      expect(f:concat()).to.be_equal_to('ab')
      expect(g:concat()).to.be_equal_to('ab')
    end)
  end)

  describe('format dispatch', function()
    it('should dispatch nil type correctly', function()
      local f = StringFormatter(styles.minimal)
      f:format(nil)
      expect(f:concat()).to.be_equal_to('nil')
    end)

    it('should dispatch boolean type correctly', function()
      local f = StringFormatter(styles.minimal)
      f:format(true)
      expect(f:concat()).to.be_equal_to('true')
    end)

    it('should dispatch number type correctly', function()
      local f = StringFormatter(styles.minimal)
      f:format(42)
      expect(f:concat()).to.be_equal_to('42')
    end)

    it('should dispatch string type correctly', function()
      local f = StringFormatter(styles.minimal)
      f:format('hi')
      expect(f:concat()).to.be_equal_to("'hi'")
    end)
  end)
end)

describe('TypeVerbosity', function()
  it('should have Field variant', function()
    expect(TypeVerbosity.Field).to_not.be_nil()
  end)

  it('should have TypeField variant', function()
    expect(TypeVerbosity.TypeField).to_not.be_nil()
  end)

  it('should have ModuleTypeField variant', function()
    expect(TypeVerbosity.ModuleTypeField).to_not.be_nil()
  end)
end)

describe('styles', function()
  it('should have minimal style', function()
    expect(styles.minimal).to_not.be_nil()
  end)

  it('should have abbrev style', function()
    expect(styles.abbrev).to_not.be_nil()
  end)

  it('should have struct style', function()
    expect(styles.struct).to_not.be_nil()
  end)

  it('should have correct delimiter for minimal style', function()
    expect(styles.minimal.delimiter).to.be_equal_to(',')
  end)

  it('should have correct delimiter for abbrev style', function()
    expect(styles.abbrev.delimiter).to.be_equal_to(', ')
  end)

  it('should not include final delimiter for minimal style', function()
    expect(styles.minimal.include_final_delimiter).to.be_false()
  end)

  it('should include final delimiter for struct style', function()
    expect(styles.struct.include_final_delimiter).to.be_true()
  end)

  it('should not use multiline tables for minimal style', function()
    expect(styles.minimal.multiline_tables).to.be_false()
  end)

  it('should use multiline tables for struct style', function()
    expect(styles.struct.multiline_tables).to.be_true()
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

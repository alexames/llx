local unit = require 'llx.unit'
local llx = require 'llx'

local dump_value_module = require 'llx.debug.dump_value'
local dump_value = dump_value_module.dump_value

local terminal_colors_module = require 'llx.debug.terminal_colors'
local color = terminal_colors_module.color
local reset = terminal_colors_module.reset

local print_module = require 'llx.debug.print'
local p = print_module.p

local trace_module = require 'llx.debug.trace'
local trace = trace_module.trace

_ENV = unit.create_test_env(_ENV)

-- =============================================================================
-- dump_value
-- =============================================================================

describe('dump_value', function()
  describe('primitive types', function()
    it('should represent numbers', function()
      expect(dump_value(42)).to.be_equal_to('42')
    end)

    it('should represent zero', function()
      expect(dump_value(0)).to.be_equal_to('0')
    end)

    it('should represent negative numbers', function()
      expect(dump_value(-7)).to.be_equal_to('-7')
    end)

    it('should represent floating point numbers', function()
      expect(dump_value(3.14)).to.be_equal_to('3.14')
    end)

    it('should represent true', function()
      expect(dump_value(true)).to.be_equal_to('true')
    end)

    it('should represent false', function()
      expect(dump_value(false)).to.be_equal_to('false')
    end)

    it('should represent nil', function()
      expect(dump_value(nil)).to.be_equal_to('nil')
    end)
  end)

  describe('string values', function()
    it('should wrap strings in single quotes', function()
      expect(dump_value('hello')).to.be_equal_to("'hello'")
    end)

    it('should handle empty strings', function()
      expect(dump_value('')).to.be_equal_to("''")
    end)

    it('should handle strings with spaces', function()
      expect(dump_value('hello world')).to.be_equal_to("'hello world'")
    end)

    it('should handle strings with special characters', function()
      expect(dump_value('line1\nline2')).to.be_equal_to("'line1\nline2'")
    end)
  end)

  describe('array tables (lists)', function()
    it('should represent an empty table', function()
      expect(dump_value({})).to.be_equal_to('{}')
    end)

    it('should represent a simple list without indices', function()
      local result = dump_value({1, 2, 3})
      expect(result).to.be_equal_to('{1,2,3}')
    end)

    it('should represent a list of strings', function()
      local result = dump_value({'a', 'b', 'c'})
      expect(result).to.be_equal_to("{\'a\',\'b\',\'c\'}")
    end)

    it('should represent a list of mixed types', function()
      local result = dump_value({1, 'two', true})
      expect(result).to.be_equal_to("{1,'two',true}")
    end)
  end)

  describe('map tables', function()
    it('should represent a table with string keys', function()
      local result = dump_value({x = 1})
      expect(result).to.be_equal_to('{x=1}')
    end)

    it('should represent a table with non-sequential numeric keys', function()
      -- Numeric keys that don't form a contiguous list starting at 1
      local t = {}
      t[5] = 'five'
      local result = dump_value(t)
      expect(result).to.be_equal_to("{[5]='five'}")
    end)
  end)

  describe('nested tables', function()
    it('should represent nested arrays', function()
      local result = dump_value({{1, 2}, {3, 4}})
      expect(result).to.be_equal_to('{{1,2},{3,4}}')
    end)

    it('should represent nested maps', function()
      local result = dump_value({inner = {a = 1}})
      expect(result).to.be_equal_to('{inner={a=1}}')
    end)
  end)

  describe('circular reference detection', function()
    it('should detect a direct self-reference', function()
      local t = {}
      t.self = t
      local result = dump_value(t)
      -- The self-referencing value should use tostring(t) instead of recursing
      expect(result).to.contain('self=')
      expect(result).to.contain('table:')
    end)

    it('should detect an indirect circular reference', function()
      local a = {}
      local b = {}
      a.ref = b
      b.ref = a
      local result = dump_value(a)
      -- Should contain the tostring representation for the back-reference
      expect(result).to.contain('table:')
    end)
  end)

  describe('function values', function()
    it('should represent functions via tostring', function()
      local result = dump_value(function() end)
      expect(result).to.contain('function:')
    end)
  end)
end)

-- =============================================================================
-- terminal_colors
-- =============================================================================

describe('terminal_colors', function()
  describe('color definitions', function()
    it('should define standard colors with fg and bg fields', function()
      local tc = terminal_colors_module
      expect(tc.red.fg).to.be_equal_to(31)
      expect(tc.red.bg).to.be_equal_to(41)
    end)

    it('should define green', function()
      local tc = terminal_colors_module
      expect(tc.green.fg).to.be_equal_to(32)
      expect(tc.green.bg).to.be_equal_to(42)
    end)

    it('should define blue', function()
      local tc = terminal_colors_module
      expect(tc.blue.fg).to.be_equal_to(34)
      expect(tc.blue.bg).to.be_equal_to(44)
    end)

    it('should define yellow', function()
      local tc = terminal_colors_module
      expect(tc.yellow.fg).to.be_equal_to(33)
      expect(tc.yellow.bg).to.be_equal_to(43)
    end)

    it('should define black', function()
      local tc = terminal_colors_module
      expect(tc.black.fg).to.be_equal_to(30)
      expect(tc.black.bg).to.be_equal_to(40)
    end)

    it('should define white', function()
      local tc = terminal_colors_module
      expect(tc.white.fg).to.be_equal_to(37)
      expect(tc.white.bg).to.be_equal_to(47)
    end)

    it('should define magenta', function()
      local tc = terminal_colors_module
      expect(tc.magenta.fg).to.be_equal_to(35)
      expect(tc.magenta.bg).to.be_equal_to(45)
    end)

    it('should define cyan', function()
      local tc = terminal_colors_module
      expect(tc.cyan.fg).to.be_equal_to(36)
      expect(tc.cyan.bg).to.be_equal_to(46)
    end)
  end)

  describe('bright color definitions', function()
    it('should define bright_red', function()
      local tc = terminal_colors_module
      expect(tc.bright_red.fg).to.be_equal_to(91)
      expect(tc.bright_red.bg).to.be_equal_to(101)
    end)

    it('should define bright_green', function()
      local tc = terminal_colors_module
      expect(tc.bright_green.fg).to.be_equal_to(92)
      expect(tc.bright_green.bg).to.be_equal_to(102)
    end)

    it('should define bright_blue', function()
      local tc = terminal_colors_module
      expect(tc.bright_blue.fg).to.be_equal_to(94)
      expect(tc.bright_blue.bg).to.be_equal_to(104)
    end)

    it('should define bright_yellow', function()
      local tc = terminal_colors_module
      expect(tc.bright_yellow.fg).to.be_equal_to(93)
      expect(tc.bright_yellow.bg).to.be_equal_to(103)
    end)

    it('should define bright_black', function()
      local tc = terminal_colors_module
      expect(tc.bright_black.fg).to.be_equal_to(90)
      expect(tc.bright_black.bg).to.be_equal_to(100)
    end)

    it('should define bright_white', function()
      local tc = terminal_colors_module
      expect(tc.bright_white.fg).to.be_equal_to(97)
      expect(tc.bright_white.bg).to.be_equal_to(107)
    end)

    it('should define bright_magenta', function()
      local tc = terminal_colors_module
      expect(tc.bright_magenta.fg).to.be_equal_to(95)
      expect(tc.bright_magenta.bg).to.be_equal_to(105)
    end)

    it('should define bright_cyan', function()
      local tc = terminal_colors_module
      expect(tc.bright_cyan.fg).to.be_equal_to(96)
      expect(tc.bright_cyan.bg).to.be_equal_to(106)
    end)
  end)

  describe('color() function', function()
    it('should return an ANSI escape code for a foreground color', function()
      local tc = terminal_colors_module
      local result = color(tc.red)
      expect(result).to.be_equal_to('\27[31m')
    end)

    it('should return an ANSI escape code for a background color', function()
      local tc = terminal_colors_module
      local result = color(nil, tc.blue)
      expect(result).to.be_equal_to('\27[44m')
    end)

    it('should return an ANSI escape code for both fg and bg', function()
      local tc = terminal_colors_module
      local result = color(tc.red, tc.blue)
      expect(result).to.be_equal_to('\27[31;44m')
    end)

    it('should return a string', function()
      local tc = terminal_colors_module
      local result = color(tc.green)
      expect(type(result)).to.be_equal_to('string')
    end)

    it('should start with ESC[', function()
      local tc = terminal_colors_module
      local result = color(tc.cyan)
      expect(result).to.start_with('\27[')
    end)

    it('should end with m', function()
      local tc = terminal_colors_module
      local result = color(tc.yellow)
      expect(result).to.end_with('m')
    end)
  end)

  describe('reset() function', function()
    it('should return the ANSI reset code', function()
      local result = reset()
      expect(result).to.be_equal_to('\27[0m')
    end)

    it('should return a string', function()
      local result = reset()
      expect(type(result)).to.be_equal_to('string')
    end)
  end)
end)

-- =============================================================================
-- p() - debug print that returns its arguments
-- =============================================================================

describe('p', function()
  it('should return a single value unchanged', function()
    local result = p(42)
    expect(result).to.be_equal_to(42)
  end)

  it('should return a string value unchanged', function()
    local result = p('hello')
    expect(result).to.be_equal_to('hello')
  end)

  it('should return nil when called with nil', function()
    local result = p(nil)
    expect(result).to.be_nil()
  end)

  it('should return false when called with false', function()
    local result = p(false)
    expect(result).to.be_false()
  end)

  it('should return true when called with true', function()
    local result = p(true)
    expect(result).to.be_true()
  end)

  it('should return multiple values unchanged', function()
    local a, b, c = p(1, 'two', true)
    expect(a).to.be_equal_to(1)
    expect(b).to.be_equal_to('two')
    expect(c).to.be_true()
  end)

  it('should return no values when called with no arguments', function()
    local result = p()
    expect(result).to.be_nil()
  end)

  it('should preserve table identity', function()
    local t = {1, 2, 3}
    local result = p(t)
    expect(result).to.be_equal_to(t)
  end)
end)

-- =============================================================================
-- trace() - debug trace with source location, returns its arguments
-- =============================================================================

describe('trace', function()
  it('should return a single value unchanged', function()
    local result = trace(42)
    expect(result).to.be_equal_to(42)
  end)

  it('should return a string value unchanged', function()
    local result = trace('hello')
    expect(result).to.be_equal_to('hello')
  end)

  it('should return nil when called with nil', function()
    local result = trace(nil)
    expect(result).to.be_nil()
  end)

  it('should return false when called with false', function()
    local result = trace(false)
    expect(result).to.be_false()
  end)

  it('should return multiple values unchanged', function()
    local a, b, c = trace(1, 'two', true)
    expect(a).to.be_equal_to(1)
    expect(b).to.be_equal_to('two')
    expect(c).to.be_true()
  end)

  it('should return no values when called with no arguments', function()
    local result = trace()
    expect(result).to.be_nil()
  end)

  it('should preserve table identity', function()
    local t = {key = 'value'}
    local result = trace(t)
    expect(result).to.be_equal_to(t)
  end)
end)

-- =============================================================================
-- llx.debug module integration
-- =============================================================================

describe('llx.debug module', function()
  it('should expose dump_value', function()
    expect(type(llx.debug.dump_value)).to.be_equal_to('function')
  end)

  it('should expose p', function()
    expect(type(llx.debug.p)).to.be_equal_to('function')
  end)

  it('should expose trace', function()
    expect(type(llx.debug.trace)).to.be_equal_to('function')
  end)

  it('should expose color', function()
    expect(type(llx.debug.color)).to.be_equal_to('function')
  end)

  it('should expose reset', function()
    expect(type(llx.debug.reset)).to.be_equal_to('function')
  end)

  it('should expose color name tables', function()
    expect(type(llx.debug.red)).to.be_equal_to('table')
    expect(type(llx.debug.green)).to.be_equal_to('table')
    expect(type(llx.debug.blue)).to.be_equal_to('table')
  end)

  it('should expose printtable', function()
    expect(type(llx.debug.printtable)).to.be_equal_to('function')
  end)

  it('should expose printlist', function()
    expect(type(llx.debug.printlist)).to.be_equal_to('function')
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

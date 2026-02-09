local proxy_module = require 'llx.proxy'
local unit = require 'llx.unit'
local llx = require 'llx'

local Proxy = proxy_module.Proxy
local set_proxy_value = proxy_module.set_proxy_value
local extract_proxy_value = proxy_module.extract_proxy_value

_ENV = unit.create_test_env(_ENV)

describe('Proxy', function()
  describe('creation', function()
    it('should create a proxy wrapping a numeric value', function()
      local p = Proxy(42)
      expect(extract_proxy_value(p)).to.be_equal_to(42)
    end)

    it('should create a proxy wrapping a string', function()
      local p = Proxy('hello')
      expect(extract_proxy_value(p)).to.be_equal_to('hello')
    end)

    it('should create a proxy wrapping a table', function()
      local t = {1, 2, 3}
      local p = Proxy(t)
      expect(extract_proxy_value(p)).to.be_equal_to(t)
    end)

    it('should create a proxy wrapping a function', function()
      local fn = function() return 99 end
      local p = Proxy(fn)
      expect(extract_proxy_value(p)).to.be_equal_to(fn)
    end)

    it('should create a proxy wrapping a boolean', function()
      local p = Proxy(true)
      expect(extract_proxy_value(p)).to.be_true()
    end)
  end)

  describe('extract_proxy_value', function()
    it('should extract a numeric value', function()
      local p = Proxy(42)
      expect(extract_proxy_value(p)).to.be_equal_to(42)
    end)

    it('should extract a string value', function()
      local p = Proxy('hello')
      expect(extract_proxy_value(p)).to.be_equal_to('hello')
    end)

    it('should extract a table value', function()
      local t = {x = 10}
      local p = Proxy(t)
      expect(extract_proxy_value(p)).to.be_equal_to(t)
    end)

    it('should extract nil when created with no argument', function()
      local p = Proxy()
      expect(extract_proxy_value(p)).to.be_nil()
    end)

    it('should extract false without confusion with nil', function()
      local p = Proxy(false)
      expect(extract_proxy_value(p)).to.be_false()
    end)
  end)

  describe('set_proxy_value', function()
    it('should change the wrapped value', function()
      local p = Proxy(10)
      set_proxy_value(p, 20)
      expect(extract_proxy_value(p)).to.be_equal_to(20)
    end)

    it('should allow setting to nil', function()
      local p = Proxy(10)
      set_proxy_value(p, nil)
      expect(extract_proxy_value(p)).to.be_nil()
    end)

    it('should allow changing type of wrapped value', function()
      local p = Proxy(42)
      set_proxy_value(p, 'now a string')
      expect(extract_proxy_value(p)).to.be_equal_to('now a string')
    end)

    it('should allow setting to a table', function()
      local p = Proxy(42)
      local t = {a = 1}
      set_proxy_value(p, t)
      expect(extract_proxy_value(p)).to.be_equal_to(t)
    end)
  end)

  describe('arithmetic metamethods', function()
    it('should support addition (proxy + number)', function()
      local p = Proxy(10)
      expect(p + 5).to.be_equal_to(15)
    end)

    it('should support addition (number + proxy)', function()
      local p = Proxy(10)
      expect(5 + p).to.be_equal_to(15)
    end)

    it('should support addition (proxy + proxy)', function()
      local p1 = Proxy(10)
      local p2 = Proxy(20)
      expect(p1 + p2).to.be_equal_to(30)
    end)

    it('should support subtraction', function()
      local p = Proxy(10)
      expect(p - 3).to.be_equal_to(7)
    end)

    it('should support subtraction (number - proxy)', function()
      local p = Proxy(3)
      expect(10 - p).to.be_equal_to(7)
    end)

    it('should support multiplication', function()
      local p = Proxy(6)
      expect(p * 7).to.be_equal_to(42)
    end)

    it('should support multiplication (number * proxy)', function()
      local p = Proxy(7)
      expect(6 * p).to.be_equal_to(42)
    end)

    it('should support division', function()
      local p = Proxy(10)
      expect(p / 2).to.be_equal_to(5.0)
    end)

    it('should support division (number / proxy)', function()
      local p = Proxy(2)
      expect(10 / p).to.be_equal_to(5.0)
    end)

    it('should support modulo', function()
      local p = Proxy(10)
      expect(p % 3).to.be_equal_to(1)
    end)

    it('should support modulo (number % proxy)', function()
      local p = Proxy(3)
      expect(10 % p).to.be_equal_to(1)
    end)

    it('should support exponentiation', function()
      local p = Proxy(2)
      expect(p ^ 10).to.be_equal_to(1024.0)
    end)

    it('should support exponentiation (number ^ proxy)', function()
      local p = Proxy(10)
      expect(2 ^ p).to.be_equal_to(1024.0)
    end)

    it('should support unary minus', function()
      local p = Proxy(42)
      expect(-p).to.be_equal_to(-42)
    end)

    it('should support unary minus on negative value', function()
      local p = Proxy(-10)
      expect(-p).to.be_equal_to(10)
    end)

    it('should support floor division', function()
      local p = Proxy(7)
      expect(p // 2).to.be_equal_to(3)
    end)

    it('should support floor division (number // proxy)', function()
      local p = Proxy(2)
      expect(7 // p).to.be_equal_to(3)
    end)
  end)

  describe('bitwise metamethods', function()
    it('should support bitwise AND', function()
      local p = Proxy(0xFF)
      expect(p & 0x0F).to.be_equal_to(0x0F)
    end)

    it('should support bitwise AND (number & proxy)', function()
      local p = Proxy(0x0F)
      expect(0xFF & p).to.be_equal_to(0x0F)
    end)

    it('should support bitwise OR', function()
      local p = Proxy(0xF0)
      expect(p | 0x0F).to.be_equal_to(0xFF)
    end)

    it('should support bitwise OR (number | proxy)', function()
      local p = Proxy(0x0F)
      expect(0xF0 | p).to.be_equal_to(0xFF)
    end)

    it('should support bitwise XOR', function()
      local p = Proxy(0xFF)
      expect(p ~ 0x0F).to.be_equal_to(0xF0)
    end)

    it('should support bitwise XOR (number ~ proxy)', function()
      local p = Proxy(0x0F)
      expect(0xFF ~ p).to.be_equal_to(0xF0)
    end)

    it('should support bitwise NOT', function()
      local p = Proxy(0)
      expect(~p).to.be_equal_to(-1)
    end)

    it('should support left shift', function()
      local p = Proxy(1)
      expect(p << 4).to.be_equal_to(16)
    end)

    it('should support left shift (number << proxy)', function()
      local p = Proxy(4)
      expect(1 << p).to.be_equal_to(16)
    end)

    it('should support right shift', function()
      local p = Proxy(16)
      expect(p >> 2).to.be_equal_to(4)
    end)

    it('should support right shift (number >> proxy)', function()
      local p = Proxy(2)
      expect(16 >> p).to.be_equal_to(4)
    end)
  end)

  describe('comparison metamethods', function()
    -- Note: In Lua 5.4, __eq is only called when both operands share the
    -- same metatable. Two different Proxy objects have different metatables,
    -- so __eq is not invoked for proxy-to-proxy comparison. We test __lt
    -- and __le which work across different metatables.

    it('should support less than (proxy < proxy)', function()
      local p1 = Proxy(1)
      local p2 = Proxy(2)
      expect(p1 < p2).to.be_true()
    end)

    it('should correctly evaluate less than when false', function()
      local p1 = Proxy(2)
      local p2 = Proxy(1)
      expect(p1 < p2).to.be_false()
    end)

    it('should correctly evaluate less than when equal values', function()
      local p1 = Proxy(5)
      local p2 = Proxy(5)
      expect(p1 < p2).to.be_false()
    end)

    it('should support less than or equal (proxy <= proxy) with equal values', function()
      local p1 = Proxy(1)
      local p2 = Proxy(1)
      expect(p1 <= p2).to.be_true()
    end)

    it('should correctly evaluate less than or equal when strictly less', function()
      local p1 = Proxy(1)
      local p2 = Proxy(2)
      expect(p1 <= p2).to.be_true()
    end)

    it('should correctly evaluate less than or equal when false', function()
      local p1 = Proxy(3)
      local p2 = Proxy(2)
      expect(p1 <= p2).to.be_false()
    end)

    it('should support less than with number on right (proxy < number)', function()
      local p = Proxy(1)
      expect(p < 5).to.be_true()
    end)

    it('should support less than with number on left (number < proxy)', function()
      local p = Proxy(5)
      expect(1 < p).to.be_true()
    end)

    it('should support less than or equal with number (proxy <= number)', function()
      local p = Proxy(5)
      expect(p <= 5).to.be_true()
    end)
  end)

  describe('concat metamethod', function()
    it('should support concatenation (proxy .. string)', function()
      local p = Proxy('hello')
      expect(p .. ' world').to.be_equal_to('hello world')
    end)

    it('should support concatenation (string .. proxy)', function()
      local p = Proxy('world')
      expect('hello ' .. p).to.be_equal_to('hello world')
    end)

    it('should support concatenation (proxy .. proxy)', function()
      local p1 = Proxy('foo')
      local p2 = Proxy('bar')
      expect(p1 .. p2).to.be_equal_to('foobar')
    end)

    it('should support concatenating numbers as strings', function()
      local p = Proxy(42)
      expect(p .. ' is the answer').to.be_equal_to('42 is the answer')
    end)
  end)

  describe('len metamethod', function()
    it('should return length of wrapped string', function()
      local p = Proxy('hello')
      expect(#p).to.be_equal_to(5)
    end)

    it('should return length of wrapped table', function()
      local p = Proxy({1, 2, 3, 4})
      expect(#p).to.be_equal_to(4)
    end)

    it('should return 0 for empty table', function()
      local p = Proxy({})
      expect(#p).to.be_equal_to(0)
    end)

    it('should return 0 for empty string', function()
      local p = Proxy('')
      expect(#p).to.be_equal_to(0)
    end)
  end)

  describe('call metamethod', function()
    it('should forward calls to wrapped function', function()
      local p = Proxy(function(x) return x * 2 end)
      expect(p(5)).to.be_equal_to(10)
    end)

    it('should pass multiple arguments', function()
      local p = Proxy(function(a, b, c) return a + b + c end)
      expect(p(1, 2, 3)).to.be_equal_to(6)
    end)

    it('should work with no arguments', function()
      local p = Proxy(function() return 'called' end)
      expect(p()).to.be_equal_to('called')
    end)

    it('should return multiple values', function()
      local p = Proxy(function() return 1, 2, 3 end)
      local a, b, c = p()
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to(2)
      expect(c).to.be_equal_to(3)
    end)
  end)

  describe('tostring metamethod', function()
    it('should convert wrapped number to string', function()
      local p = Proxy(42)
      expect(tostring(p)).to.be_equal_to('42')
    end)

    it('should convert wrapped string to same string', function()
      local p = Proxy('hello')
      expect(tostring(p)).to.be_equal_to('hello')
    end)

    it('should convert wrapped boolean to string', function()
      local p = Proxy(true)
      expect(tostring(p)).to.be_equal_to('true')
    end)
  end)

  describe('index metamethod', function()
    it('should forward string key index to wrapped table', function()
      local t = {x = 10, y = 20}
      local p = Proxy(t)
      expect(p.x).to.be_equal_to(10)
      expect(p.y).to.be_equal_to(20)
    end)

    it('should return nil for missing key', function()
      local t = {x = 10}
      local p = Proxy(t)
      expect(p.z).to.be_nil()
    end)

    it('should forward non-colliding numeric index', function()
      -- Note: index 1 is used internally by the proxy to store the wrapped
      -- value, so rawget finds it directly. Index 2+ goes through __index.
      local t = {10, 20, 30}
      local p = Proxy(t)
      expect(p[2]).to.be_equal_to(20)
      expect(p[3]).to.be_equal_to(30)
    end)

    it('should forward nested table access', function()
      local t = {nested = {value = 42}}
      local p = Proxy(t)
      expect(p.nested.value).to.be_equal_to(42)
    end)
  end)

  describe('newindex metamethod', function()
    it('should forward string key assignment to wrapped table', function()
      local t = {}
      local p = Proxy(t)
      p.x = 42
      expect(t.x).to.be_equal_to(42)
    end)

    it('should forward non-colliding numeric index assignment', function()
      -- Note: index 1 is used internally, so we use index 2+
      local t = {0, 0, 0}
      local p = Proxy(t)
      p[2] = 'second'
      expect(t[2]).to.be_equal_to('second')
    end)

    it('should overwrite existing value in wrapped table', function()
      local t = {x = 10}
      local p = Proxy(t)
      p.x = 20
      expect(t.x).to.be_equal_to(20)
    end)

    it('should add new key to wrapped table', function()
      local t = {a = 1}
      local p = Proxy(t)
      p.b = 2
      expect(t.b).to.be_equal_to(2)
    end)
  end)

  describe('value swapping', function()
    it('should reflect new value after set_proxy_value in arithmetic', function()
      local p = Proxy(10)
      expect(p + 1).to.be_equal_to(11)
      set_proxy_value(p, 20)
      expect(p + 1).to.be_equal_to(21)
    end)

    it('should reflect new value after set_proxy_value in tostring', function()
      local p = Proxy(10)
      expect(tostring(p)).to.be_equal_to('10')
      set_proxy_value(p, 'hello')
      expect(tostring(p)).to.be_equal_to('hello')
    end)

    it('should reflect new value after set_proxy_value in len', function()
      local p = Proxy({1, 2, 3})
      expect(#p).to.be_equal_to(3)
      set_proxy_value(p, {1, 2, 3, 4, 5})
      expect(#p).to.be_equal_to(5)
    end)

    it('should reflect new value after set_proxy_value in index', function()
      local t1 = {a = 1}
      local t2 = {a = 2}
      local p = Proxy(t1)
      expect(p.a).to.be_equal_to(1)
      set_proxy_value(p, t2)
      expect(p.a).to.be_equal_to(2)
    end)

    it('should reflect new value after set_proxy_value in call', function()
      local p = Proxy(function() return 'first' end)
      expect(p()).to.be_equal_to('first')
      set_proxy_value(p, function() return 'second' end)
      expect(p()).to.be_equal_to('second')
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

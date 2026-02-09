local operators = require 'llx.operators'
local unit = require 'llx.unit'
local llx = require 'llx'

_ENV = unit.create_test_env(_ENV)

describe('operators', function()
  describe('add', function()
    it('should add two positive integers', function()
      expect(operators.add(2, 3)).to.be_equal_to(5)
    end)

    it('should add negative numbers', function()
      expect(operators.add(-1, -2)).to.be_equal_to(-3)
    end)

    it('should add with zero', function()
      expect(operators.add(5, 0)).to.be_equal_to(5)
    end)

    it('should add floating point numbers', function()
      expect(operators.add(1.5, 2.5)).to.be_equal_to(4.0)
    end)
  end)

  describe('sub', function()
    it('should subtract two positive integers', function()
      expect(operators.sub(10, 3)).to.be_equal_to(7)
    end)

    it('should subtract resulting in negative', function()
      expect(operators.sub(3, 10)).to.be_equal_to(-7)
    end)

    it('should subtract zero', function()
      expect(operators.sub(5, 0)).to.be_equal_to(5)
    end)

    it('should subtract floating point numbers', function()
      expect(operators.sub(5.5, 2.5)).to.be_equal_to(3.0)
    end)
  end)

  describe('mul', function()
    it('should multiply two positive integers', function()
      expect(operators.mul(6, 7)).to.be_equal_to(42)
    end)

    it('should multiply by zero', function()
      expect(operators.mul(100, 0)).to.be_equal_to(0)
    end)

    it('should multiply by one', function()
      expect(operators.mul(42, 1)).to.be_equal_to(42)
    end)

    it('should multiply negative numbers', function()
      expect(operators.mul(-3, -4)).to.be_equal_to(12)
    end)

    it('should multiply mixed sign numbers', function()
      expect(operators.mul(-3, 4)).to.be_equal_to(-12)
    end)
  end)

  describe('div', function()
    it('should divide two integers evenly', function()
      expect(operators.div(10, 2)).to.be_equal_to(5.0)
    end)

    it('should divide with remainder', function()
      expect(operators.div(7, 2)).to.be_equal_to(3.5)
    end)

    it('should divide by one', function()
      expect(operators.div(42, 1)).to.be_equal_to(42.0)
    end)

    it('should divide negative by positive', function()
      expect(operators.div(-10, 2)).to.be_equal_to(-5.0)
    end)
  end)

  describe('mod', function()
    it('should compute modulo with no remainder', function()
      expect(operators.mod(10, 5)).to.be_equal_to(0)
    end)

    it('should compute modulo with remainder', function()
      expect(operators.mod(10, 3)).to.be_equal_to(1)
    end)

    it('should compute modulo of 1', function()
      expect(operators.mod(7, 1)).to.be_equal_to(0)
    end)

    it('should compute modulo with larger divisor', function()
      expect(operators.mod(3, 10)).to.be_equal_to(3)
    end)
  end)

  describe('pow', function()
    it('should compute power of two integers', function()
      expect(operators.pow(2, 10)).to.be_equal_to(1024.0)
    end)

    it('should compute power of zero', function()
      expect(operators.pow(5, 0)).to.be_equal_to(1.0)
    end)

    it('should compute power of one', function()
      expect(operators.pow(5, 1)).to.be_equal_to(5.0)
    end)

    it('should compute square', function()
      expect(operators.pow(3, 2)).to.be_equal_to(9.0)
    end)

    it('should compute cube', function()
      expect(operators.pow(2, 3)).to.be_equal_to(8.0)
    end)
  end)

  describe('unm', function()
    it('should negate a positive number', function()
      expect(operators.unm(42)).to.be_equal_to(-42)
    end)

    it('should negate a negative number', function()
      expect(operators.unm(-10)).to.be_equal_to(10)
    end)

    it('should negate zero', function()
      expect(operators.unm(0)).to.be_equal_to(0)
    end)

    it('should negate a floating point number', function()
      expect(operators.unm(3.14)).to.be_equal_to(-3.14)
    end)
  end)

  describe('idiv', function()
    it('should floor divide evenly', function()
      expect(operators.idiv(10, 2)).to.be_equal_to(5)
    end)

    it('should floor divide with remainder', function()
      expect(operators.idiv(7, 2)).to.be_equal_to(3)
    end)

    it('should floor divide negative by positive', function()
      expect(operators.idiv(-7, 2)).to.be_equal_to(-4)
    end)

    it('should floor divide by one', function()
      expect(operators.idiv(42, 1)).to.be_equal_to(42)
    end)
  end)

  describe('band', function()
    it('should AND all ones with mask', function()
      expect(operators.band(0xFF, 0x0F)).to.be_equal_to(0x0F)
    end)

    it('should AND with zero', function()
      expect(operators.band(0xFF, 0x00)).to.be_equal_to(0)
    end)

    it('should AND identical values', function()
      expect(operators.band(0xAB, 0xAB)).to.be_equal_to(0xAB)
    end)

    it('should AND non-overlapping bits', function()
      expect(operators.band(0xF0, 0x0F)).to.be_equal_to(0)
    end)
  end)

  describe('bor', function()
    it('should OR two complementary bytes', function()
      expect(operators.bor(0xF0, 0x0F)).to.be_equal_to(0xFF)
    end)

    it('should OR with zero', function()
      expect(operators.bor(0xAB, 0x00)).to.be_equal_to(0xAB)
    end)

    it('should OR identical values', function()
      expect(operators.bor(0xAB, 0xAB)).to.be_equal_to(0xAB)
    end)

    it('should OR two zeros', function()
      expect(operators.bor(0, 0)).to.be_equal_to(0)
    end)
  end)

  describe('bxor', function()
    it('should XOR to get difference bits', function()
      expect(operators.bxor(0xFF, 0x0F)).to.be_equal_to(0xF0)
    end)

    it('should XOR identical values to zero', function()
      expect(operators.bxor(0xAB, 0xAB)).to.be_equal_to(0)
    end)

    it('should XOR with zero', function()
      expect(operators.bxor(0xAB, 0x00)).to.be_equal_to(0xAB)
    end)

    it('should XOR complementary bytes', function()
      expect(operators.bxor(0xF0, 0x0F)).to.be_equal_to(0xFF)
    end)
  end)

  describe('bnot', function()
    it('should NOT zero to all ones (negative one in signed)', function()
      expect(operators.bnot(0)).to.be_equal_to(-1)
    end)

    it('should NOT negative one to zero', function()
      expect(operators.bnot(-1)).to.be_equal_to(0)
    end)

    it('should be its own inverse', function()
      expect(operators.bnot(operators.bnot(42))).to.be_equal_to(42)
    end)

    it('should NOT 1 to -2', function()
      expect(operators.bnot(1)).to.be_equal_to(-2)
    end)
  end)

  describe('shl', function()
    it('should shift left by 1', function()
      expect(operators.shl(1, 1)).to.be_equal_to(2)
    end)

    it('should shift left by 4', function()
      expect(operators.shl(1, 4)).to.be_equal_to(16)
    end)

    it('should shift left by 0', function()
      expect(operators.shl(42, 0)).to.be_equal_to(42)
    end)

    it('should shift left multiplying by powers of two', function()
      expect(operators.shl(3, 3)).to.be_equal_to(24)
    end)
  end)

  describe('shr', function()
    it('should shift right by 1', function()
      expect(operators.shr(4, 1)).to.be_equal_to(2)
    end)

    it('should shift right by 4', function()
      expect(operators.shr(256, 4)).to.be_equal_to(16)
    end)

    it('should shift right by 0', function()
      expect(operators.shr(42, 0)).to.be_equal_to(42)
    end)

    it('should shift right discarding bits', function()
      expect(operators.shr(7, 1)).to.be_equal_to(3)
    end)
  end)

  describe('concat', function()
    it('should concatenate two strings', function()
      expect(operators.concat('hello', ' world')).to.be_equal_to('hello world')
    end)

    it('should concatenate empty strings', function()
      expect(operators.concat('', '')).to.be_equal_to('')
    end)

    it('should concatenate with empty string on left', function()
      expect(operators.concat('', 'hello')).to.be_equal_to('hello')
    end)

    it('should concatenate with empty string on right', function()
      expect(operators.concat('hello', '')).to.be_equal_to('hello')
    end)

    it('should concatenate numbers as strings', function()
      expect(operators.concat(1, 2)).to.be_equal_to('12')
    end)
  end)

  describe('len', function()
    it('should return length of a string', function()
      expect(operators.len('hello')).to.be_equal_to(5)
    end)

    it('should return length of empty string', function()
      expect(operators.len('')).to.be_equal_to(0)
    end)

    it('should return length of a table', function()
      expect(operators.len({1, 2, 3})).to.be_equal_to(3)
    end)

    it('should return length of empty table', function()
      expect(operators.len({})).to.be_equal_to(0)
    end)
  end)

  describe('eq', function()
    it('should return true for equal numbers', function()
      expect(operators.eq(42, 42)).to.be_true()
    end)

    it('should return false for unequal numbers', function()
      expect(operators.eq(42, 43)).to.be_false()
    end)

    it('should return true for equal strings', function()
      expect(operators.eq('hello', 'hello')).to.be_true()
    end)

    it('should return false for unequal strings', function()
      expect(operators.eq('hello', 'world')).to.be_false()
    end)

    it('should return true for same table reference', function()
      local t = {}
      expect(operators.eq(t, t)).to.be_true()
    end)

    it('should return false for different table references', function()
      expect(operators.eq({}, {})).to.be_false()
    end)
  end)

  describe('lt', function()
    it('should return true when first is less', function()
      expect(operators.lt(1, 2)).to.be_true()
    end)

    it('should return false when first is greater', function()
      expect(operators.lt(2, 1)).to.be_false()
    end)

    it('should return false when equal', function()
      expect(operators.lt(5, 5)).to.be_false()
    end)

    it('should compare negative numbers', function()
      expect(operators.lt(-2, -1)).to.be_true()
    end)

    it('should compare strings lexicographically', function()
      expect(operators.lt('apple', 'banana')).to.be_true()
    end)
  end)

  describe('le', function()
    it('should return true when first is less', function()
      expect(operators.le(1, 2)).to.be_true()
    end)

    it('should return true when equal', function()
      expect(operators.le(5, 5)).to.be_true()
    end)

    it('should return false when first is greater', function()
      expect(operators.le(2, 1)).to.be_false()
    end)

    it('should compare negative numbers', function()
      expect(operators.le(-2, -1)).to.be_true()
    end)

    it('should compare strings lexicographically', function()
      expect(operators.le('apple', 'banana')).to.be_true()
    end)

    it('should return true for equal strings', function()
      expect(operators.le('hello', 'hello')).to.be_true()
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

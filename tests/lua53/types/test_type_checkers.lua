-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- The String tests that need the Lua 5.3 integer operators,
-- which no earlier Lua can parse. tests/init.lua loads this file only
-- on Lua 5.3 and later.

local unit = require 'llx.unit'
local llx = require 'llx'

local Boolean = llx.Boolean
local Float = llx.Float
local Integer = llx.Integer
local Nil = llx.Nil
local Function = llx.Function
local Thread = llx.Thread
local Userdata = llx.Userdata
local Number = llx.Number
local String = llx.String

local isinstance = llx.isinstance

local _ENV = unit.create_test_env(_ENV)

describe('String (Lua 5.3+ operators)', function()
  describe('__shl (left rotate)', function()
    it('should rotate left by 1', function()
      expect('abcde' << 1).to.be_equal_to('bcdea')
    end)

    it('should rotate left by 2', function()
      expect('abcde' << 2).to.be_equal_to('cdeab')
    end)

    it('should return same string for rotation of 0', function()
      expect('abcde' << 0).to.be_equal_to('abcde')
    end)
  end)

  describe('__shr (right rotate)', function()
    it('should rotate right by 1', function()
      expect('abcde' >> 1).to.be_equal_to('eabcd')
    end)

    it('should rotate right by 2', function()
      expect('abcde' >> 2).to.be_equal_to('deabc')
    end)

    it('should return the same string for rotation of 0', function()
      expect('abcde' >> 0).to.be_equal_to('abcde')
    end)
  end)

  describe('negative rotation', function()
    it('should rotate right when shifted left by a negative count',
        function()
      expect('abcde' << -1).to.be_equal_to('eabcd')
    end)

    it('should rotate left when shifted right by a negative count',
        function()
      expect('abcde' >> -2).to.be_equal_to('cdeab')
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end

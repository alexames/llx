-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- The Proxy tests that need the Lua 5.3 integer operators,
-- which no earlier Lua can parse. tests/init.lua loads this file only
-- on Lua 5.3 and later.

local proxy_module = require 'llx.proxy'
local unit = require 'llx.unit'
local llx = require 'llx'

local Proxy = proxy_module.Proxy
local set_proxy_value = proxy_module.set_proxy_value
local extract_proxy_value = proxy_module.extract_proxy_value

local _ENV = unit.create_test_env(_ENV)

describe('Proxy (Lua 5.3+ operators)', function()
  it('should support floor division', function()
    local p = Proxy(7)
    expect(p // 2).to.be_equal_to(3)
  end)

  it('should support floor division (number // proxy)', function()
    local p = Proxy(2)
    expect(7 // p).to.be_equal_to(3)
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
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end

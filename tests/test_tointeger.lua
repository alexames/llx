local unit = require 'llx.unit'
local llx = require 'llx'

local tointeger_module = require 'llx.tointeger'
local tointeger = tointeger_module.tointeger

_ENV = unit.create_test_env(_ENV)

describe('tointeger', function()
  describe('integer values', function()
    it('should pass through positive integers', function()
      expect(tointeger(5)).to.be_equal_to(5)
    end)

    it('should pass through zero', function()
      expect(tointeger(0)).to.be_equal_to(0)
    end)

    it('should pass through negative integers', function()
      expect(tointeger(-3)).to.be_equal_to(-3)
    end)

    it('should pass through large integers', function()
      expect(tointeger(1000000)).to.be_equal_to(1000000)
    end)
  end)

  describe('float values', function()
    it('should floor positive floats', function()
      expect(tointeger(3.7)).to.be_equal_to(3)
    end)

    it('should floor values just below an integer', function()
      expect(tointeger(4.999)).to.be_equal_to(4)
    end)

    it('should floor positive floats with small fractional parts', function()
      expect(tointeger(2.1)).to.be_equal_to(2)
    end)

    it('should floor negative floats toward negative infinity', function()
      expect(tointeger(-2.5)).to.be_equal_to(-3)
    end)

    it('should floor 0.5 to 0', function()
      expect(tointeger(0.5)).to.be_equal_to(0)
    end)

    it('should handle float-represented integers', function()
      expect(tointeger(5.0)).to.be_equal_to(5)
    end)
  end)

  describe('custom __tointeger metamethod', function()
    it('should delegate to __tointeger when present', function()
      local obj = setmetatable({value = 42}, {
        __tointeger = function(self)
          return self.value
        end
      })
      expect(tointeger(obj)).to.be_equal_to(42)
    end)

    it('should use __tointeger result over default behavior', function()
      local obj = setmetatable({}, {
        __tointeger = function(self)
          return 99
        end
      })
      expect(tointeger(obj)).to.be_equal_to(99)
    end)

    it('should allow __tointeger to return negative values', function()
      local obj = setmetatable({}, {
        __tointeger = function(self)
          return -10
        end
      })
      expect(tointeger(obj)).to.be_equal_to(-10)
    end)

    it('should allow __tointeger to return zero', function()
      local obj = setmetatable({}, {
        __tointeger = function(self)
          return 0
        end
      })
      expect(tointeger(obj)).to.be_equal_to(0)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

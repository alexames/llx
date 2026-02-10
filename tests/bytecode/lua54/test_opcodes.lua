local unit = require 'llx.unit'
local llx = require 'llx'

local opcodes_module = require 'llx.bytecode.lua54.opcodes'
local opcodes = opcodes_module.opcodes

_ENV = unit.create_test_env(_ENV)

describe('bytecode opcodes', function()
  describe('OP_MOVE', function()
    it('should have value 0', function()
      expect(opcodes.OP_MOVE.value).to.be_equal_to(0)
    end)

    it('should have name OP_MOVE', function()
      expect(opcodes.OP_MOVE.name).to.be_equal_to('OP_MOVE')
    end)
  end)

  describe('forward lookup by integer', function()
    it('should return OP_MOVE for index 0', function()
      expect(opcodes[0]).to_not.be_nil()
      expect(opcodes[0].name).to.be_equal_to('OP_MOVE')
    end)

    it('should return OP_LOADI for index 1', function()
      expect(opcodes[1].name).to.be_equal_to('OP_LOADI')
    end)

    it('should return OP_LOADTRUE for index 7', function()
      expect(opcodes[7].name).to.be_equal_to('OP_LOADTRUE')
    end)

    it('should return OP_EXTRAARG for index 82', function()
      expect(opcodes[82].name).to.be_equal_to('OP_EXTRAARG')
    end)
  end)

  describe('reverse lookup by name', function()
    it('should return value 0 for OP_MOVE', function()
      expect(opcodes.OP_MOVE.value).to.be_equal_to(0)
    end)

    it('should return value 70 for OP_RETURN', function()
      expect(opcodes.OP_RETURN.value).to.be_equal_to(70)
    end)

    it('should return the same object for index and name lookups', function()
      expect(opcodes[0]).to.be_equal_to(opcodes.OP_MOVE)
      expect(opcodes[70]).to.be_equal_to(opcodes.OP_RETURN)
      expect(opcodes[82]).to.be_equal_to(opcodes.OP_EXTRAARG)
    end)
  end)

  describe('key opcodes have correct values', function()
    it('OP_LOADI should be 1', function()
      expect(opcodes.OP_LOADI.value).to.be_equal_to(1)
    end)

    it('OP_LOADK should be 3', function()
      expect(opcodes.OP_LOADK.value).to.be_equal_to(3)
    end)

    it('OP_ADD should be 34', function()
      expect(opcodes.OP_ADD.value).to.be_equal_to(34)
    end)

    it('OP_RETURN should be 70', function()
      expect(opcodes.OP_RETURN.value).to.be_equal_to(70)
    end)

    it('OP_EXTRAARG should be 82', function()
      expect(opcodes.OP_EXTRAARG.value).to.be_equal_to(82)
    end)
  end)

  describe('OP_EXTRAARG is last opcode', function()
    it('should have value 82', function()
      expect(opcodes.OP_EXTRAARG.value).to.be_equal_to(82)
    end)

    it('should have no opcode at index 83', function()
      expect(opcodes[83]).to.be_nil()
    end)
  end)

  describe('total number of opcodes', function()
    it('should have 83 opcodes (0 through 82)', function()
      local count = 0
      for i = 0, 82 do
        if opcodes[i] ~= nil then
          count = count + 1
        end
      end
      expect(count).to.be_equal_to(83)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

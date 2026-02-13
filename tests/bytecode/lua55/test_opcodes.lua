local unit = require 'llx.unit'
local llx = require 'llx'

local opcodes_module = require 'llx.bytecode.lua55.opcodes'
local opcodes = opcodes_module.opcodes

_ENV = unit.create_test_env(_ENV)

describe('bytecode opcodes (lua55)', function()
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

    it('should return OP_ADD for index 34', function()
      expect(opcodes[34].name).to.be_equal_to('OP_ADD')
    end)

    it('should return OP_EXTRAARG for index 82', function()
      expect(opcodes[82].name).to.be_equal_to('OP_EXTRAARG')
    end)
  end)

  describe('opcodes match 5.4', function()
    it('OP_RETURN0 should be 71', function()
      expect(opcodes.OP_RETURN0.value).to.be_equal_to(71)
    end)

    it('OP_VARARGPREP should be 81', function()
      expect(opcodes.OP_VARARGPREP.value).to.be_equal_to(81)
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

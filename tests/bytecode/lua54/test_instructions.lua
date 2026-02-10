local unit = require 'llx.unit'
local llx = require 'llx'

local instructions_module = require 'llx.bytecode.lua54.instructions'
local Instruction = instructions_module.Instruction

_ENV = unit.create_test_env(_ENV)

describe('bytecode instructions', function()
  local dummy_proto = {}

  describe('field extraction', function()
    it('should extract opcode (i) from low 7 bits', function()
      -- bits 0-6 = 1, all other bits zero
      local instr = Instruction(0x00000001, dummy_proto)
      expect(instr:i()).to.be_equal_to(1)
    end)

    it('should extract opcode with max 7-bit value', function()
      -- bits 0-6 all set = 127
      local instr = Instruction(0x0000007F, dummy_proto)
      expect(instr:i()).to.be_equal_to(127)
    end)

    it('should extract A field from bits 7-14', function()
      -- A=1: 1 << 7 = 0x80
      local instr = Instruction(1 << 7, dummy_proto)
      expect(instr:A()).to.be_equal_to(1)
    end)

    it('should extract A field with max 8-bit value', function()
      -- A=255: 255 << 7 = 0x7F80
      local instr = Instruction(255 << 7, dummy_proto)
      expect(instr:A()).to.be_equal_to(255)
    end)

    it('should extract k flag from bit 15', function()
      -- k=1: 1 << 15 = 0x8000
      local instr = Instruction(1 << 15, dummy_proto)
      expect(instr:k()).to.be_equal_to(1)
    end)

    it('should extract k=0 when bit 15 is clear', function()
      local instr = Instruction(0x00000000, dummy_proto)
      expect(instr:k()).to.be_equal_to(0)
    end)

    it('should extract B field from bits 16-23', function()
      -- B=1: 1 << 16 = 0x10000
      local instr = Instruction(1 << 16, dummy_proto)
      expect(instr:B()).to.be_equal_to(1)
    end)

    it('should extract B field with max 8-bit value', function()
      -- B=255: 255 << 16 = 0xFF0000
      local instr = Instruction(255 << 16, dummy_proto)
      expect(instr:B()).to.be_equal_to(255)
    end)

    it('should extract C field from bits 24-31', function()
      -- C=1: 1 << 24 = 0x01000000
      local instr = Instruction(1 << 24, dummy_proto)
      expect(instr:C()).to.be_equal_to(1)
    end)

    it('should extract C field with max 8-bit value', function()
      -- C=255: 255 << 24 = 0xFF000000
      local instr = Instruction(255 << 24, dummy_proto)
      expect(instr:C()).to.be_equal_to(255)
    end)

    it('should extract Bx from bits 15-31 (17 bits)', function()
      -- Bx=1: 1 << 15 = 0x8000
      local instr = Instruction(1 << 15, dummy_proto)
      expect(instr:Bx()).to.be_equal_to(1)
    end)

    it('should extract Bx with a larger value', function()
      -- Bx=1000: 1000 << 15
      local instr = Instruction(1000 << 15, dummy_proto)
      expect(instr:Bx()).to.be_equal_to(1000)
    end)

    it('should extract Bx with max 17-bit value', function()
      -- Bx max = 2^17 - 1 = 131071
      local instr = Instruction(131071 << 15, dummy_proto)
      expect(instr:Bx()).to.be_equal_to(131071)
    end)

    it('should extract sBx as signed (excess-K with K=65535)', function()
      -- sBx=0 is encoded as 65535 in the raw Bx field
      -- raw Bx = sBx + 65535, so sBx = raw Bx - 65535
      -- sBx=0: raw Bx=65535, bytecode = 65535 << 15
      local instr = Instruction(65535 << 15, dummy_proto)
      expect(instr:sBx()).to.be_equal_to(0)
    end)

    it('should extract positive sBx', function()
      -- sBx=1: raw Bx = 1 + 65535 = 65536, bytecode = 65536 << 15
      local instr = Instruction(65536 << 15, dummy_proto)
      expect(instr:sBx()).to.be_equal_to(1)
    end)

    it('should extract negative sBx', function()
      -- sBx=-1: raw Bx = -1 + 65535 = 65534, bytecode = 65534 << 15
      local instr = Instruction(65534 << 15, dummy_proto)
      expect(instr:sBx()).to.be_equal_to(-1)
    end)

    it('should extract Ax from bits 7-31 (25 bits)', function()
      -- Ax=1: 1 << 7 = 0x80
      local instr = Instruction(1 << 7, dummy_proto)
      expect(instr:Ax()).to.be_equal_to(1)
    end)

    it('should extract Ax with a larger value', function()
      -- Ax=12345: 12345 << 7
      local instr = Instruction(12345 << 7, dummy_proto)
      expect(instr:Ax()).to.be_equal_to(12345)
    end)

    it('should extract sJ as signed (excess-K with K=16777215)', function()
      -- sJ=0: raw = 0 + 16777215 = 16777215, bytecode = 16777215 << 7
      local instr = Instruction(16777215 << 7, dummy_proto)
      expect(instr:sJ()).to.be_equal_to(0)
    end)

    it('should extract positive sJ', function()
      -- sJ=1: raw = 1 + 16777215 = 16777216, bytecode = 16777216 << 7
      local instr = Instruction(16777216 << 7, dummy_proto)
      expect(instr:sJ()).to.be_equal_to(1)
    end)

    it('should extract negative sJ', function()
      -- sJ=-1: raw = -1 + 16777215 = 16777214, bytecode = 16777214 << 7
      local instr = Instruction(16777214 << 7, dummy_proto)
      expect(instr:sJ()).to.be_equal_to(-1)
    end)

    it('should extract sB as signed (excess-K with K=127)', function()
      -- sB=0: raw B = 0 + 127 = 127, bytecode = 127 << 16
      local instr = Instruction(127 << 16, dummy_proto)
      expect(instr:sB()).to.be_equal_to(0)
    end)

    it('should extract positive sB', function()
      -- sB=1: raw B = 1 + 127 = 128, bytecode = 128 << 16
      local instr = Instruction(128 << 16, dummy_proto)
      expect(instr:sB()).to.be_equal_to(1)
    end)

    it('should extract negative sB', function()
      -- sB=-1: raw B = -1 + 127 = 126, bytecode = 126 << 16
      local instr = Instruction(126 << 16, dummy_proto)
      expect(instr:sB()).to.be_equal_to(-1)
    end)

    it('should extract vB from bits 16-21 (6 bits)', function()
      -- vB=1: 1 << 16
      local instr = Instruction(1 << 16, dummy_proto)
      expect(instr:vB()).to.be_equal_to(1)
    end)

    it('should extract vB with max 6-bit value', function()
      -- vB max = 63: 63 << 16
      local instr = Instruction(63 << 16, dummy_proto)
      expect(instr:vB()).to.be_equal_to(63)
    end)

    it('should extract vC from bits 22-31 (10 bits)', function()
      -- vC=1: 1 << 22
      local instr = Instruction(1 << 22, dummy_proto)
      expect(instr:vC()).to.be_equal_to(1)
    end)

    it('should extract vC with max 10-bit value', function()
      -- vC max = 1023: 1023 << 22
      local instr = Instruction(1023 << 22, dummy_proto)
      expect(instr:vC()).to.be_equal_to(1023)
    end)
  end)

  describe('composite instructions', function()
    it('should decode OP_MOVE (opcode 0) with A=1, B=2', function()
      -- OP_MOVE = opcode 0, A=1, B=2
      -- bytecode = 0 | (1 << 7) | (2 << 16) = 0x00020080
      local instr = Instruction(0x00020080, dummy_proto)
      expect(instr:i()).to.be_equal_to(0)
      expect(instr:A()).to.be_equal_to(1)
      expect(instr:B()).to.be_equal_to(2)
    end)

    it('should decode OP_LOADI (opcode 1) with A=0, sBx=1', function()
      -- OP_LOADI = opcode 1, A=0, sBx=1
      -- raw Bx = 1 + 65535 = 65536
      -- bytecode = 1 | (0 << 7) | (65536 << 15)
      local bytecode = 1 | (0 << 7) | (65536 << 15)
      local instr = Instruction(bytecode, dummy_proto)
      expect(instr:i()).to.be_equal_to(1)
      expect(instr:A()).to.be_equal_to(0)
      expect(instr:sBx()).to.be_equal_to(1)
    end)

    it('should decode instruction with all iABC fields set', function()
      -- opcode=5, A=10, k=1, B=20, C=30
      local bytecode = 5 | (10 << 7) | (1 << 15) | (20 << 16) | (30 << 24)
      local instr = Instruction(bytecode, dummy_proto)
      expect(instr:i()).to.be_equal_to(5)
      expect(instr:A()).to.be_equal_to(10)
      expect(instr:k()).to.be_equal_to(1)
      expect(instr:B()).to.be_equal_to(20)
      expect(instr:C()).to.be_equal_to(30)
    end)

    it('should decode instruction with A and Bx fields', function()
      -- opcode=3, A=5, Bx=500
      -- bytecode = 3 | (5 << 7) | (500 << 15)
      local bytecode = 3 | (5 << 7) | (500 << 15)
      local instr = Instruction(bytecode, dummy_proto)
      expect(instr:i()).to.be_equal_to(3)
      expect(instr:A()).to.be_equal_to(5)
      expect(instr:Bx()).to.be_equal_to(500)
    end)

    it('should not confuse adjacent fields', function()
      -- Set only B=255 (bits 16-23 all ones), verify neighboring fields are 0
      local bytecode = 255 << 16
      local instr = Instruction(bytecode, dummy_proto)
      expect(instr:i()).to.be_equal_to(0)
      expect(instr:A()).to.be_equal_to(0)
      expect(instr:k()).to.be_equal_to(0)
      expect(instr:B()).to.be_equal_to(255)
      expect(instr:C()).to.be_equal_to(0)
    end)

    it('should decode zero bytecode as all-zero fields', function()
      local instr = Instruction(0x00000000, dummy_proto)
      expect(instr:i()).to.be_equal_to(0)
      expect(instr:A()).to.be_equal_to(0)
      expect(instr:k()).to.be_equal_to(0)
      expect(instr:B()).to.be_equal_to(0)
      expect(instr:C()).to.be_equal_to(0)
      expect(instr:Bx()).to.be_equal_to(0)
      expect(instr:Ax()).to.be_equal_to(0)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

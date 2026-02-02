local opcodes_module = require 'opcodes'

local opcodes = opcodes_module.opcodes
local function R(arg)
  return {
    repr = function(self, instruction)
      return instruction[arg](instruction)
    end,
    str = function(self, instruction)
      return string.format('R[%i]', instruction[arg](instruction))
    end,
    arg = arg,
  }
end
local function K(arg)
  return {
    repr = function(self, instruction)
      return instruction[arg](instruction)
    end,
    str = function(self, instruction)
      return instruction._proto.k[instruction[arg](instruction) + 1]
    end,
    arg = arg,
  }
end
local function RK(arg)
  return {
    repr = function(self, instruction)
      return instruction[arg](instruction)
    end,
    str = function(self, instruction)
      if instruction:k() == 1 then
        return instruction._proto.k[instruction[arg](instruction) + 1]
      else
        return string.format('R[%i]', instruction[arg](instruction))
      end
    end,
    arg = arg,
  }
end
local function UpValue(arg)
  return {
    repr = function(self, instruction)
      return instruction[arg](instruction)
    end,
    str = function(self, instruction)
      return instruction._proto.upvalues[instruction[arg](instruction) + 1].name
    end,
    arg = arg,
  }
end
local function Value(arg)
  return {
    repr = function(self, instruction)
      return instruction[arg](instruction)
    end,
    str = function(self, instruction)
      return instruction[arg](instruction)
    end,
    arg = arg,
  }
end
local function KPROTO(arg)
  return {
    repr = function(self, instruction)
      return instruction[arg](instruction)
    end,
    str = function(self, instruction)
      return instruction[arg](instruction)
    end,
    arg = arg,
  }
end

local op_code_arg_metatable = {

}
local function OpCodeArg(args)
  return {
    repr = function(self, instruction)
      local result = ''
      for i, v in ipairs(args) do
        result = result 
                 .. ', '
                 .. string.format('%s=%i', v.arg, v:repr(instruction))
      end
      return result
    end,

    str = function(self, instruction)
      local result = ''
      for i, v in ipairs(args) do
        result = result
                  .. ', '
                  .. string.format('%s=%s', v.arg, v:str(instruction))
      end
      return result
    end,
  }
end

local opcode_args = {
  [opcodes.OP_MOVE]       = OpCodeArg{R'A', R'B'},
  [opcodes.OP_LOADI]      = OpCodeArg{R'A', Value'sBx'},
  [opcodes.OP_LOADF]      = OpCodeArg{R'A', Value'sBx'},
  [opcodes.OP_LOADK]      = OpCodeArg{R'A', K'Bx'},
  [opcodes.OP_LOADKX]     = OpCodeArg{R'A'},
  [opcodes.OP_LOADFALSE]  = OpCodeArg{R'A'},
  [opcodes.OP_LFALSESKIP] = OpCodeArg{R'A'},
  [opcodes.OP_LOADTRUE]   = OpCodeArg{R'A'},
  [opcodes.OP_LOADNIL]    = OpCodeArg{R'A', Value'B'},
  [opcodes.OP_GETUPVAL]   = OpCodeArg{R'A', UpValue'B'},
  [opcodes.OP_SETUPVAL]   = OpCodeArg{R'A', UpValue'B'},

  [opcodes.OP_GETTABUP]   = OpCodeArg{R'A', UpValue'B', K'C'},
  [opcodes.OP_GETTABLE]   = OpCodeArg{R'A', R'B',       R'C'},
  [opcodes.OP_GETI]       = OpCodeArg{R'A', R'B',       Value'C'},
  [opcodes.OP_GETFIELD]   = OpCodeArg{R'A', R'B',       K'C'},

  [opcodes.OP_SETTABUP]   = OpCodeArg{UpValue'A', K'B',     RK'C', Value'k'},
  [opcodes.OP_SETTABLE]   = OpCodeArg{R'A',       R'B',     RK'C', Value'k'},
  [opcodes.OP_SETI]       = OpCodeArg{R'A',       Value'B', RK'C', Value'k'},
  [opcodes.OP_SETFIELD]   = OpCodeArg{R'A',       K'B',     RK'C', Value'k'},

  [opcodes.OP_NEWTABLE]   = OpCodeArg{R'A', Value'vB', Value'vC', Value'k'},

  [opcodes.OP_SELF]       = OpCodeArg{R'A', R'B', RK'C'},

  [opcodes.OP_ADDI]       = OpCodeArg{R'A', R'B', Value'sC'},

  [opcodes.OP_ADDK]       = OpCodeArg{R'A', R'B', K'C'},
  [opcodes.OP_SUBK]       = OpCodeArg{R'A', R'B', K'C'},
  [opcodes.OP_MULK]       = OpCodeArg{R'A', R'B', K'C'},
  [opcodes.OP_MODK]       = OpCodeArg{R'A', R'B', K'C'},
  [opcodes.OP_POWK]       = OpCodeArg{R'A', R'B', K'C'},
  [opcodes.OP_DIVK]       = OpCodeArg{R'A', R'B', K'C'},
  [opcodes.OP_IDIVK]      = OpCodeArg{R'A', R'B', K'C'},

  [opcodes.OP_BANDK]      = OpCodeArg{R'A', R'B', K'C'},
  [opcodes.OP_BORK]       = OpCodeArg{R'A', R'B', K'C'},
  [opcodes.OP_BXORK]      = OpCodeArg{R'A', R'B', K'C'},

  [opcodes.OP_SHRI]       = OpCodeArg{R'A', R'B', Value'sC'},
  [opcodes.OP_SHLI]       = OpCodeArg{R'A', R'B', Value'sC'},

  [opcodes.OP_ADD]        = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_SUB]        = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_MUL]        = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_MOD]        = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_POW]        = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_DIV]        = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_IDIV]       = OpCodeArg{R'A', R'B', R'C'},

  [opcodes.OP_BAND]       = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_BOR]        = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_BXOR]       = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_SHL]        = OpCodeArg{R'A', R'B', R'C'},
  [opcodes.OP_SHR]        = OpCodeArg{R'A', R'B', R'C'},

  [opcodes.OP_MMBIN]      = OpCodeArg{R'A', R'B',      Value'C'},
  [opcodes.OP_MMBINI]     = OpCodeArg{R'A', Value'sB', Value'C'},
  [opcodes.OP_MMBINK]     = OpCodeArg{R'A', K'B',      Value'C'},

  [opcodes.OP_UNM]        = OpCodeArg{R'A', R'B'},
  [opcodes.OP_BNOT]       = OpCodeArg{R'A', R'B'},
  [opcodes.OP_NOT]        = OpCodeArg{R'A', R'B'},
  [opcodes.OP_LEN]        = OpCodeArg{R'A', R'B'},

  [opcodes.OP_CONCAT]     = OpCodeArg{R'A', Value'B'},

  [opcodes.OP_CLOSE]      = OpCodeArg{R'A'},
  [opcodes.OP_TBC]        = OpCodeArg{R'A'},
  [opcodes.OP_JMP]        = OpCodeArg{Value'sJ'},
  [opcodes.OP_EQ]         = OpCodeArg{R'A', R'B', Value'k'},
  [opcodes.OP_LT]         = OpCodeArg{R'A', R'B', Value'k'},
  [opcodes.OP_LE]         = OpCodeArg{R'A', R'B', Value'k'},

  [opcodes.OP_EQK]        = OpCodeArg{R'A', K'B', Value'k'},
  [opcodes.OP_EQI]        = OpCodeArg{R'A', Value'sB', Value'k'},
  [opcodes.OP_LTI]        = OpCodeArg{R'A', Value'sB', Value'k'},
  [opcodes.OP_LEI]        = OpCodeArg{R'A', Value'sB', Value'k'},
  [opcodes.OP_GTI]        = OpCodeArg{R'A', Value'sB', Value'k'},
  [opcodes.OP_GEI]        = OpCodeArg{R'A', Value'sB', Value'k'},

  [opcodes.OP_TEST]       = OpCodeArg{R'A', Value'k'},
  [opcodes.OP_TESTSET]    = OpCodeArg{R'A', R'B', Value'k'},

  [opcodes.OP_CALL]       = OpCodeArg{R'A', Value'B', Value'C'},
  [opcodes.OP_TAILCALL]   = OpCodeArg{R'A', Value'B'},

  [opcodes.OP_RETURN]     = OpCodeArg{R'A', Value'B'},
  [opcodes.OP_RETURN0]    = OpCodeArg{R'A'},
  [opcodes.OP_RETURN1]    = OpCodeArg{R'A'},

  [opcodes.OP_FORLOOP]    = OpCodeArg{R'A', Value'Bx'},
  [opcodes.OP_FORPREP]    = OpCodeArg{R'A', Value'Bx'},

  [opcodes.OP_TFORPREP]   = OpCodeArg{R'A', Value'Bx'},
  [opcodes.OP_TFORCALL]   = OpCodeArg{R'A', Value'C'},
  [opcodes.OP_TFORLOOP]   = OpCodeArg{R'A', Value'B'},

  [opcodes.OP_SETLIST]    = OpCodeArg{R'A', Value'vB', Value'vC'},

  [opcodes.OP_CLOSURE]    = OpCodeArg{R'A', KPROTO'Bx'},

  [opcodes.OP_VARARG]     = OpCodeArg{R'A', Value'C'},

  [opcodes.OP_VARARGPREP] = OpCodeArg{R'A'},

  [opcodes.OP_EXTRAARG]   = OpCodeArg{Value'Ax'},
}

local function hex(v)
  return string.format('0x%X', v)
end

local function extract_bits(start, size, signed)
  local bitmask = ~(~0 << size)
  return function(self)
    local signed_offset = signed and bitmask >> 1 or 0
    return ((self._bytecode >> start) & bitmask) - signed_offset
  end
end

-- We assume that instructions are unsigned 32-bit integers.
-- All instructions have an opcode in the first 7 bits.
-- Instructions can have the following formats:
--       |3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0|
--       |1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0|
-- iABC  |      C(8)     |      B(8)     |k|     A(8)      |   Op(7)     |
-- ivABC |      vC(10)     |     vB(6)   |k|     A(8)      |   Op(7)     |
-- iABx  |            Bx(17)               |     A(8)      |   Op(7)     |
-- iAsBx |           sBx (signed)(17)      |     A(8)      |   Op(7)     |
-- iAx   |                      Ax(25)                     |   Op(7)     |
-- isJ   |                      sJ (signed)(25)            |   Op(7)     |
--
-- ('v' stands for "variant", 's' for "signed", 'x' for "extended".)
-- A signed argument is represented in excess K: The represented value is
-- the written unsigned value minus K, where K is half (rounded down) the
-- maximum value for the corresponding unsigned argument.
local instruction_metatable = {
  i   = extract_bits(0,              7),
  A   = extract_bits(7,              8),
  k   = extract_bits(7 + 8,          1),
  B   = extract_bits(7 + 8 + 1,      8),
  sB  = extract_bits(7 + 8 + 1,      8, true),
  C   = extract_bits(7 + 8 + 1 + 8,  8),

  vB  = extract_bits(7 + 8 + 1,      6),
  vC  = extract_bits(7 + 8 + 1 + 6, 10),

  Bx  = extract_bits(7 + 8,         17),
  sBx = extract_bits(7 + 8,         17, true),
  Ax  = extract_bits(7,             25),
  sJ  = extract_bits(7,             25, true),

  __tostring = function(self)
    local i = self:i()
    local op = opcodes[i]
    local args = opcode_args[op]
    local instruction_string = string.format(
      'Instruction{i=%s%s},', op.name, args:repr(self))
    return string.format('%-50s\t--[[0x%08X%s]]', instruction_string, self._bytecode, args:str(self))
  end,
}

instruction_metatable.__index = instruction_metatable
function Instruction(bytecode, proto)
  return setmetatable({_bytecode = bytecode, _proto=proto}, instruction_metatable)
end

return {
  Instruction
}

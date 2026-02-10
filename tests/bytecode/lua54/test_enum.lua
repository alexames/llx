local unit = require 'llx.unit'
local llx = require 'llx'

local enum_module = require 'llx.bytecode.lua54.enum'
local enum = enum_module.enum

_ENV = unit.create_test_env(_ENV)

describe('bytecode enum', function()
  describe('creation', function()
    it('should create an enum from integer keys mapping to names', function()
      local opcodes = enum {
        [0] = 'MOVE',
        [1] = 'LOADI',
        [2] = 'LOADF',
      }
      expect(opcodes).to_not.be_nil()
      expect(type(opcodes)).to.be_equal_to('table')
    end)
  end)

  describe('forward lookup', function()
    it('should return an enum object when looked up by integer key', function()
      local opcodes = enum {
        [0] = 'MOVE',
        [1] = 'LOADI',
      }
      local obj = opcodes[0]
      expect(obj).to_not.be_nil()
      expect(type(obj)).to.be_equal_to('table')
    end)

    it('should have the correct .name field on forward lookup', function()
      local opcodes = enum {
        [0] = 'MOVE',
        [1] = 'LOADI',
      }
      expect(opcodes[0].name).to.be_equal_to('MOVE')
      expect(opcodes[1].name).to.be_equal_to('LOADI')
    end)

    it('should have the correct .value field on forward lookup', function()
      local opcodes = enum {
        [0] = 'MOVE',
        [1] = 'LOADI',
      }
      expect(opcodes[0].value).to.be_equal_to(0)
      expect(opcodes[1].value).to.be_equal_to(1)
    end)
  end)

  describe('reverse lookup', function()
    it('should return an enum object when looked up by string name', function()
      local opcodes = enum {
        [0] = 'MOVE',
        [1] = 'LOADI',
      }
      local obj = opcodes['MOVE']
      expect(obj).to_not.be_nil()
      expect(type(obj)).to.be_equal_to('table')
    end)

    it('should have the correct .name field on reverse lookup', function()
      local opcodes = enum {
        [0] = 'MOVE',
        [1] = 'LOADI',
      }
      expect(opcodes['MOVE'].name).to.be_equal_to('MOVE')
      expect(opcodes['LOADI'].name).to.be_equal_to('LOADI')
    end)

    it('should have the correct .value field on reverse lookup', function()
      local opcodes = enum {
        [0] = 'MOVE',
        [1] = 'LOADI',
      }
      expect(opcodes['MOVE'].value).to.be_equal_to(0)
      expect(opcodes['LOADI'].value).to.be_equal_to(1)
    end)
  end)

  describe('enum object identity', function()
    it('should return the same object for forward and reverse lookups', function()
      local opcodes = enum {
        [0] = 'MOVE',
        [1] = 'LOADI',
      }
      expect(opcodes[0]).to.be_equal_to(opcodes['MOVE'])
      expect(opcodes[1]).to.be_equal_to(opcodes['LOADI'])
    end)
  end)

  describe('insert', function()
    it('should add a new entry accessible by integer key', function()
      local opcodes = enum {
        [0] = 'MOVE',
      }
      opcodes:insert(1, 'LOADI')
      expect(opcodes[1]).to_not.be_nil()
      expect(opcodes[1].name).to.be_equal_to('LOADI')
      expect(opcodes[1].value).to.be_equal_to(1)
    end)

    it('should add a new entry accessible by string name', function()
      local opcodes = enum {
        [0] = 'MOVE',
      }
      opcodes:insert(1, 'LOADI')
      expect(opcodes['LOADI']).to_not.be_nil()
      expect(opcodes['LOADI'].name).to.be_equal_to('LOADI')
      expect(opcodes['LOADI'].value).to.be_equal_to(1)
    end)

    it('should return the same object for both lookups after insert', function()
      local opcodes = enum {
        [0] = 'MOVE',
      }
      opcodes:insert(1, 'LOADI')
      expect(opcodes[1]).to.be_equal_to(opcodes['LOADI'])
    end)

    it('should not overwrite an existing integer key', function()
      local opcodes = enum {
        [0] = 'MOVE',
      }
      opcodes:insert(0, 'REPLACED')
      expect(opcodes[0].name).to.be_equal_to('MOVE')
    end)
  end)

  describe('non-existent keys', function()
    it('should return nil for an absent integer key', function()
      local opcodes = enum {
        [0] = 'MOVE',
      }
      expect(opcodes[99]).to.be_nil()
    end)

    it('should return nil for an absent string key', function()
      local opcodes = enum {
        [0] = 'MOVE',
      }
      expect(opcodes['NONEXISTENT']).to.be_nil()
    end)
  end)

  describe('multiple entries', function()
    it('should handle many entries with correct bidirectional lookups', function()
      local tags = enum {
        [0] = 'LUA_VNIL',
        [1] = 'LUA_VFALSE',
        [2] = 'LUA_VTRUE',
        [3] = 'LUA_VNUMINT',
        [4] = 'LUA_VNUMFLT',
        [5] = 'LUA_VSHRSTR',
        [6] = 'LUA_VLNGSTR',
      }
      expect(tags[0].name).to.be_equal_to('LUA_VNIL')
      expect(tags[6].name).to.be_equal_to('LUA_VLNGSTR')
      expect(tags['LUA_VNIL'].value).to.be_equal_to(0)
      expect(tags['LUA_VLNGSTR'].value).to.be_equal_to(6)
      expect(tags[3]).to.be_equal_to(tags['LUA_VNUMINT'])
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

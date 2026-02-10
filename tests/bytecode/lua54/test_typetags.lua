local unit = require 'llx.unit'
local llx = require 'llx'

local typetags_module = require 'llx.bytecode.lua54.typetags'
local typetags = typetags_module.typetags
local makevariant = typetags_module.makevariant

_ENV = unit.create_test_env(_ENV)

describe('bytecode typetags', function()
  describe('base type values', function()
    it('tnil should have value 0', function()
      expect(typetags.tnil.value).to.be_equal_to(0)
    end)

    it('tboolean should have value 1', function()
      expect(typetags.tboolean.value).to.be_equal_to(1)
    end)

    it('tlightuserdata should have value 2', function()
      expect(typetags.tlightuserdata.value).to.be_equal_to(2)
    end)

    it('tnumber should have value 3', function()
      expect(typetags.tnumber.value).to.be_equal_to(3)
    end)

    it('tstring should have value 4', function()
      expect(typetags.tstring.value).to.be_equal_to(4)
    end)

    it('ttable should have value 5', function()
      expect(typetags.ttable.value).to.be_equal_to(5)
    end)

    it('tfunction should have value 6', function()
      expect(typetags.tfunction.value).to.be_equal_to(6)
    end)

    it('tuserdata should have value 7', function()
      expect(typetags.tuserdata.value).to.be_equal_to(7)
    end)

    it('tthread should have value 8', function()
      expect(typetags.tthread.value).to.be_equal_to(8)
    end)
  end)

  describe('base type names', function()
    it('should have correct name for each base type', function()
      expect(typetags.tnil.name).to.be_equal_to('tnil')
      expect(typetags.tboolean.name).to.be_equal_to('tboolean')
      expect(typetags.tlightuserdata.name).to.be_equal_to('tlightuserdata')
      expect(typetags.tnumber.name).to.be_equal_to('tnumber')
      expect(typetags.tstring.name).to.be_equal_to('tstring')
      expect(typetags.ttable.name).to.be_equal_to('ttable')
      expect(typetags.tfunction.name).to.be_equal_to('tfunction')
      expect(typetags.tuserdata.name).to.be_equal_to('tuserdata')
      expect(typetags.tthread.name).to.be_equal_to('tthread')
    end)
  end)

  describe('makevariant', function()
    it('should compute base_type | (variant << 4)', function()
      expect(makevariant(typetags.tnil, 0)).to.be_equal_to(0)
      expect(makevariant(typetags.tnil, 1)).to.be_equal_to(16)
      expect(makevariant(typetags.tnil, 2)).to.be_equal_to(32)
      expect(makevariant(typetags.tnil, 3)).to.be_equal_to(48)
    end)

    it('should produce correct values for number variants', function()
      expect(makevariant(typetags.tnumber, 0)).to.be_equal_to(3)
      expect(makevariant(typetags.tnumber, 1)).to.be_equal_to(19)
    end)

    it('should produce correct values for function variants', function()
      expect(makevariant(typetags.tfunction, 0)).to.be_equal_to(6)
      expect(makevariant(typetags.tfunction, 1)).to.be_equal_to(22)
      expect(makevariant(typetags.tfunction, 2)).to.be_equal_to(38)
    end)
  end)

  describe('nil variants', function()
    it('vnil should have value 0', function()
      expect(typetags.vnil.value).to.be_equal_to(0)
    end)

    it('vempty should have value 16', function()
      expect(typetags.vempty.value).to.be_equal_to(16)
    end)

    it('vabstkey should have value 32', function()
      expect(typetags.vabstkey.value).to.be_equal_to(32)
    end)

    it('vnotable should have value 48', function()
      expect(typetags.vnotable.value).to.be_equal_to(48)
    end)
  end)

  describe('boolean variants', function()
    it('vfalse should have value 1 (1 | (0 << 4))', function()
      expect(typetags.vfalse.value).to.be_equal_to(1)
    end)

    it('vtrue should have value 17 (1 | (1 << 4))', function()
      expect(typetags.vtrue.value).to.be_equal_to(17)
    end)

    it('vfalse and vtrue should have correct names', function()
      expect(typetags.vfalse.name).to.be_equal_to('vfalse')
      expect(typetags.vtrue.name).to.be_equal_to('vtrue')
    end)
  end)

  describe('number variants', function()
    it('vnumint should have value 3 (3 | (0 << 4))', function()
      expect(typetags.vnumint.value).to.be_equal_to(3)
    end)

    it('vnumflt should have value 19 (3 | (1 << 4))', function()
      expect(typetags.vnumflt.value).to.be_equal_to(19)
    end)

    it('vnumint and vnumflt should have correct names', function()
      expect(typetags.vnumint.name).to.be_equal_to('vnumint')
      expect(typetags.vnumflt.name).to.be_equal_to('vnumflt')
    end)
  end)

  describe('string variants', function()
    it('vsrtstr should have value 4 (4 | (0 << 4))', function()
      expect(typetags.vsrtstr.value).to.be_equal_to(4)
    end)

    it('vlngstr should have value 20 (4 | (1 << 4))', function()
      expect(typetags.vlngstr.value).to.be_equal_to(20)
    end)

    it('vsrtstr and vlngstr should have correct names', function()
      expect(typetags.vsrtstr.name).to.be_equal_to('vsrtstr')
      expect(typetags.vlngstr.name).to.be_equal_to('vlngstr')
    end)
  end)

  describe('function variants', function()
    it('vlcl (Lua closure) should have value 6 (6 | (0 << 4))', function()
      expect(typetags.vlcl.value).to.be_equal_to(6)
    end)

    it('vlcf (light C function) should have value 22 (6 | (1 << 4))', function()
      expect(typetags.vlcf.value).to.be_equal_to(22)
    end)

    it('vccl (C closure) should have value 38 (6 | (2 << 4))', function()
      expect(typetags.vccl.value).to.be_equal_to(38)
    end)

    it('function variants should have correct names', function()
      expect(typetags.vlcl.name).to.be_equal_to('vlcl')
      expect(typetags.vlcf.name).to.be_equal_to('vlcf')
      expect(typetags.vccl.name).to.be_equal_to('vccl')
    end)
  end)

  describe('other variants', function()
    it('vlightuserdata should have value 2', function()
      expect(typetags.vlightuserdata.value).to.be_equal_to(2)
    end)

    it('vtable should have value 5', function()
      expect(typetags.vtable.value).to.be_equal_to(5)
    end)

    it('vuserdata should have value 7', function()
      expect(typetags.vuserdata.value).to.be_equal_to(7)
    end)

    it('vthread should have value 8', function()
      expect(typetags.vthread.value).to.be_equal_to(8)
    end)
  end)

  describe('bidirectional lookup', function()
    it('should look up base types by numeric index', function()
      expect(typetags[0].name).to.be_equal_to('tnil')
      expect(typetags[1].name).to.be_equal_to('tboolean')
      expect(typetags[2].name).to.be_equal_to('tlightuserdata')
      expect(typetags[3].name).to.be_equal_to('tnumber')
      expect(typetags[4].name).to.be_equal_to('tstring')
      expect(typetags[5].name).to.be_equal_to('ttable')
      expect(typetags[6].name).to.be_equal_to('tfunction')
      expect(typetags[7].name).to.be_equal_to('tuserdata')
      expect(typetags[8].name).to.be_equal_to('tthread')
    end)

    it('should look up variants by numeric index for unique values', function()
      expect(typetags[16].name).to.be_equal_to('vempty')
      expect(typetags[32].name).to.be_equal_to('vabstkey')
      expect(typetags[48].name).to.be_equal_to('vnotable')
      expect(typetags[17].name).to.be_equal_to('vtrue')
      expect(typetags[19].name).to.be_equal_to('vnumflt')
      expect(typetags[20].name).to.be_equal_to('vlngstr')
      expect(typetags[22].name).to.be_equal_to('vlcf')
      expect(typetags[38].name).to.be_equal_to('vccl')
    end)

    it('should look up base types by name and get correct value', function()
      expect(typetags['tnil'].value).to.be_equal_to(0)
      expect(typetags['tboolean'].value).to.be_equal_to(1)
      expect(typetags['tnumber'].value).to.be_equal_to(3)
      expect(typetags['tstring'].value).to.be_equal_to(4)
      expect(typetags['tfunction'].value).to.be_equal_to(6)
    end)

    it('should look up variants by name and get correct value', function()
      expect(typetags['vempty'].value).to.be_equal_to(16)
      expect(typetags['vabstkey'].value).to.be_equal_to(32)
      expect(typetags['vnotable'].value).to.be_equal_to(48)
      expect(typetags['vtrue'].value).to.be_equal_to(17)
      expect(typetags['vnumflt'].value).to.be_equal_to(19)
      expect(typetags['vlngstr'].value).to.be_equal_to(20)
      expect(typetags['vlcf'].value).to.be_equal_to(22)
      expect(typetags['vccl'].value).to.be_equal_to(38)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

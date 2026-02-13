local unit = require 'llx.unit'
local llx = require 'llx'

local bcode = require 'llx.bytecode.lua55.bcode'

_ENV = unit.create_test_env(_ENV)

describe('bytecode reader (lua55)', function()
  it('can parse an empty function', function()
    local bytes = string.dump(function() end)
    local proto, meta = bcode.read_bytes(bytes)
    expect(proto.code).to.be_a('table')
    expect(proto.k).to.be_a('table')
    expect(proto.p).to.be_a('table')
    expect(proto.upvalues).to.be_a('table')
    expect(proto.maxstacksize).to.be_a('number')
  end)

  it('can parse a function with constants', function()
    -- Use a float constant since small integers are inlined via LOADI
    local bytes = string.dump(function() local x = 3.14; return x end)
    local proto, meta = bcode.read_bytes(bytes)
    local found = false
    for _, v in ipairs(proto.k) do
      if v == 3.14 then
        found = true
        break
      end
    end
    expect(found).to.be_true()
  end)

  it('can parse a function with string constants', function()
    local bytes = string.dump(function() return "hello" end)
    local proto, meta = bcode.read_bytes(bytes)
    local found = false
    for _, v in ipairs(proto.k) do
      if v == "hello" then
        found = true
        break
      end
    end
    expect(found).to.be_true()
  end)

  it('can parse a function with nested functions', function()
    local bytes = string.dump(function() local f = function() end; return f end)
    local proto, meta = bcode.read_bytes(bytes)
    expect(#proto.p).to.be_greater_than(0)
  end)

  it('populates meta with version info', function()
    local bytes = string.dump(function() end)
    local proto, meta = bcode.read_bytes(bytes)
    expect(meta.version).to.be_a('table')
    expect(meta.version.major).to.be_equal_to(5)
    expect(meta.version.minor).to.be_equal_to(5)
  end)

  it('proto.code is a non-empty table of instructions', function()
    local bytes = string.dump(function() end)
    local proto, meta = bcode.read_bytes(bytes)
    expect(proto.code).to.be_a('table')
    expect(#proto.code).to.be_greater_than(0)
  end)

  it('works with vararg functions', function()
    local bytes = string.dump(function(...) end)
    local proto, meta = bcode.read_bytes(bytes)
    expect(proto.flag & 1).to.be_equal_to(1)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

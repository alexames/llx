-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- The set utilities tests that need the Lua 5.3 integer operators,
-- which no earlier Lua can parse. tests/init.lua loads this file only
-- on Lua 5.3 and later.


local unit = require 'llx.unit'
local llx = require 'llx'

require 'llx.types.set'
require 'llx.types.list'

local _ENV = unit.create_test_env(_ENV)

describe('set utilities (Lua 5.3+ operators)', function()
  it('should be accessible via __bxor operator', function()
    local a = llx.Set{1, 2, 3}
    local b = llx.Set{2, 3, 4}
    local result = a ~ b
    expect(result).to.be_equal_to(llx.Set{1, 4})
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end

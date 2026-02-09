local unit = require 'llx.unit'
local llx = require 'llx'

_ENV = unit.create_test_env(_ENV)

-- The experimental modules have side effects at load time:
-- - man.lua executes function calls and print statements on require
-- - export.lua writes to _G
--
-- These are proof-of-concept modules not suitable for standard unit
-- testing without refactoring to isolate side effects.
--
-- Modules: export, man

describe('experimental', function()
  it.todo('export: create export types with metadata and defaults')
  it.todo('export: define variables with UI hints')
  it.todo('man: attach documentation metadata to functions')
  it.todo('man: generate markdown-formatted documentation')
end)

if llx.main_file() then
  unit.run_unit_tests()
end

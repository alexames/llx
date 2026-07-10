-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- Meta-tests guarding against test files that silently run zero tests
-- (issue #69). Every tests/**/test_*.lua file must contain the
-- standalone runner footer (so CI's per-file execution actually runs
-- its suites) and must be registered in tests/init.lua (so the
-- aggregate runner picks it up).

local llx = require 'llx'
local unit = require 'llx.unit'

local describe = unit.describe
local it = unit.it
local expect = unit.expect

local THIS_BASENAME = 'test_hygiene.lua'

-- Lists every test_*.lua file at or below the directory containing
-- this file. Returns the list of paths (as reported by the shell) and
-- the tests-root prefix shared by all of them, derived from this
-- file's own entry. Returns nil if this file is not among the results,
-- which means the scan itself is broken.
local function find_test_files()
  local source = debug.getinfo(1, 'S').source
  local path = source:match('^@(.*)$') or source
  local dir = path:match('^(.*[/\\])') or ''
  local root = dir:gsub('[/\\]+$', '')
  if root == '' then
    root = '.'
  end

  local is_windows = package.config:sub(1, 1) == '\\'
  local command
  if is_windows then
    root = root:gsub('/', '\\')
    command = 'dir /b /s "' .. root .. '\\test_*.lua" 2>nul'
  else
    command = 'find "' .. root .. '" -name "test_*.lua" 2>/dev/null'
  end

  local handle = io.popen(command)
  if not handle then
    return nil
  end
  local files = {}
  local prefix
  for line in handle:lines() do
    if line ~= '' then
      table.insert(files, line)
      if line:sub(-#THIS_BASENAME) == THIS_BASENAME then
        local head = line:sub(1, -#THIS_BASENAME - 1)
        if head == '' or head:match('[/\\]$') then
          prefix = head
        end
      end
    end
  end
  handle:close()
  if not prefix then
    return nil
  end
  table.sort(files)
  return files, prefix
end

-- Converts a found file path into its llx.tests.* module name.
local function module_name(file, prefix)
  local relative = file:sub(#prefix + 1)
  return 'llx.tests.' .. relative:gsub('%.lua$', ''):gsub('[/\\]', '.')
end

describe('test suite hygiene', function()
  it('should locate the test tree', function()
    local files = find_test_files()
    expect(files).to_not.be_nil()
  end)

  it('should have the standalone runner footer in every file', function()
    local files = find_test_files()
    local missing = {}
    for _, file in ipairs(files or {}) do
      local handle = io.open(file, 'r')
      expect(handle).to_not.be_nil()
      local content = handle:read('a')
      handle:close()
      if not (content:find('main_file', 1, true)
          and content:find('run_unit_tests', 1, true)) then
        table.insert(missing, file)
      end
    end
    expect(table.concat(missing, ', ')).to.be_equal_to('')
  end)

  it('should register every test file in tests/init.lua', function()
    local files, prefix = find_test_files()
    local init_path = (prefix or '') .. 'init.lua'
    local handle = io.open(init_path, 'r')
    expect(handle).to_not.be_nil()
    local registry = handle:read('a')
    handle:close()
    local unregistered = {}
    for _, file in ipairs(files or {}) do
      local name = module_name(file, prefix)
      if not registry:find("'" .. name .. "'", 1, true) then
        table.insert(unregistered, name)
      end
    end
    expect(table.concat(unregistered, ', ')).to.be_equal_to('')
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

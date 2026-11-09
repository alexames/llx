-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- Every module the rock ships must load without writing a global,
-- llx.flow_control.switchcase excepted. A module-scope assignment that
-- escapes its module environment lands in _G, where an ordinary run
-- cannot see it and a host that locks its global table gets a
-- load-time error in place of the module.

local llx = require 'llx'
local compat = require 'llx.compat'
local unit = require 'llx.unit'
local strict = require 'llx.strict'

local _ENV = unit.create_test_env(_ENV)

-- llx.flow_control.switchcase installs its operators as globals rather
-- than returning them, which is why llx.flow_control does not
-- aggregate it. It is the one module a host with a locked global table
-- cannot load. Naming the globals here keeps the exemption honest: a
-- fifth one, or a rename, fails the suite below instead of widening a
-- hole.
local GLOBAL_INSTALLING_MODULES = {
  ['llx.flow_control.switchcase'] =
    {'case', 'default', 'switch', 'type_switch'},
}

-- Directory holding this file, with a trailing separator, so the
-- rockspec is found the same way whether the aggregate runner loaded
-- this file or the interpreter did.
local function this_directory()
  local source = debug.getinfo(1, 'S').source
  local path = source:match('^@(.*)$') or source
  return path:match('^(.*[/\\])') or ''
end

-- Whether a shipped module is meant to load on the running interpreter.
-- A compat layer loads only on the interpreters llx.compat chooses it
-- for, and the bytecode parsers only where integers are 64 bits.
local function loads_here(name)
  if name:find('^llx%.compat%.') then
    for _, layer in ipairs(compat.layers) do
      if layer == name then return true end
    end
    return false
  end
  if name:find('^llx%.bytecode%.lua5%d') then
    return compat.integer_bits == 64
  end
  return true
end

local CHECKOUT_ROOT = this_directory() .. '../../'
local ROCKSPEC_PATH = CHECKOUT_ROOT .. 'llx-scm-1.rockspec'

-- Returns the rockspec's map of module name to source path, and those
-- names sorted, or nil and a message saying why not. The rockspec is a
-- Lua chunk, so it runs in an empty environment and its assignments
-- are read back from there rather than from _G.
--
-- Its paths are relative to the checkout, which is not the working
-- directory the tests run from: the aggregate runner starts at the
-- checkout root and the per-file runs start in tests/. They are joined
-- to the root derived above so both find the same sources.
local function shipped_modules()
  local spec = {}
  local chunk, load_error = compat.loadfile(ROCKSPEC_PATH, 't', spec)
  if not chunk then
    return nil, tostring(load_error)
  end
  local ran, run_error = pcall(chunk)
  if not ran then
    return nil, tostring(run_error)
  end
  local declared = spec.build and spec.build.modules
  if type(declared) ~= 'table' then
    return nil, ROCKSPEC_PATH .. ' declares no build.modules table'
  end
  local paths = {}
  local names = {}
  for name, path in compat.pairs(declared) do
    paths[name] = CHECKOUT_ROOT .. path
    names[compat.len(names) + 1] = name
  end
  table.sort(names)
  return paths, names
end

-- Runs one module's source with a globals table of its own and returns
-- the sorted names it wrote there, or nil and a message saying why the
-- source would not run.
--
-- The private table is what makes the answer exact. A metatable on _G
-- reports only a write of a name _G does not already hold, so a name
-- some earlier unlocked load created -- which here includes every name
-- the unit framework itself writes -- is rewritten in silence. An
-- empty table holds nothing, so its __newindex sees every module-scope
-- write whatever the name and whatever the value.
--
-- Loading the file rather than requiring it also means the module body
-- runs even though package.loaded already holds the module, and that
-- the throwaway copy it builds falls away with the environment instead
-- of having to be swapped out from under the running suite.
--
-- Running a body twice is not free of side effects. llx.types.string
-- and llx.types.table extend the real `string` and `table` in place, so
-- a second run replaces those entries and their metatables with fresh
-- but equivalent copies. Nothing here depends on their identity;
-- anything that compared one of them across this call would break.
local function globals_written_by(name, path)
  local written = {}
  local seen = {}
  local function record(t, key, value)
    local written_name = tostring(key)
    if not seen[written_name] then
      seen[written_name] = true
      written[compat.len(written) + 1] = written_name
    end
    rawset(t, key, value)
  end

  -- A module that spells the write `_G.name = ...` gets this proxy in
  -- place of the real global table, so that spelling is recorded like a
  -- bare one. It is the only spelling that can leak from a module built
  -- with create_module_environment, whose bare assignments land in its
  -- own _M -- which is most of the tree. A write made with rawset
  -- escapes both this and a locked host, so neither promises to see it.
  local globals = setmetatable({}, {__index = _G, __newindex = record})

  local environment = setmetatable({}, {
    __index = function(_, key)
      if key == '_G' then
        return globals
      end
      return _G[key]
    end,
    __newindex = record,
  })

  local chunk, load_error = compat.loadfile(path, 't', environment)
  if not chunk then
    return nil, tostring(load_error)
  end
  -- require hands a module its name and its origin; a module that
  -- reads them has to see the same two values here.
  local ran, run_error = pcall(chunk, name, path)
  if not ran then
    return nil, tostring(run_error)
  end
  table.sort(written)
  return written
end

-- Runs `run` with the llx section of package.loaded emptied, so that a
-- require in it runs the module bodies rather than having the cache
-- handed back, then restores that section and every global. The
-- framework running this test holds closures over its own copies of
-- these modules, and a second set of classes swapped in underneath
-- would not compare equal to them.
--
-- `run` returns whether its require succeeded and what it raised;
-- this returns true, or false and that error as a string.
local function with_llx_unloaded(run)
  local loaded_before = {}
  for module_name, module in compat.pairs(package.loaded) do
    if module_name == 'llx' or module_name:find('^llx%.') then
      loaded_before[module_name] = module
    end
  end
  local globals_before = {}
  for name, value in compat.pairs(_G) do
    globals_before[name] = value
  end

  for module_name in compat.pairs(loaded_before) do
    package.loaded[module_name] = nil
  end

  local loaded, result = run()

  for name in compat.pairs(_G) do
    if globals_before[name] == nil then
      _G[name] = nil
    end
  end
  for name, value in compat.pairs(globals_before) do
    _G[name] = value
  end
  for module_name in compat.pairs(package.loaded) do
    if module_name == 'llx' or module_name:find('^llx%.') then
      package.loaded[module_name] = nil
    end
  end
  for module_name, module in compat.pairs(loaded_before) do
    package.loaded[module_name] = module
  end

  if loaded then
    return true
  end
  return false, tostring(result)
end

-- Requires llx.unit from scratch with the global table locked.
-- Returns true, or false and the error it raised.
--
-- Every name the framework's own modules write is cleared from _G
-- first. Without that the check passes whether or not the leak is
-- fixed: this file's header required llx.unit unlocked, so a leaked
-- name is already present, and a write to a name _G holds never
-- reaches __newindex.
local function require_unit_under_lock(paths)
  -- Collected before package.loaded is emptied, because a module body
  -- run here requires its own dependencies, which refills the cache
  -- that is about to be cleared.
  local framework_globals = {}
  for module_name, path in compat.pairs(paths) do
    if module_name == 'llx.unit'
        or module_name:find('^llx%.unit%.') then
      local written = globals_written_by(module_name, path) or {}
      for _, name in ipairs(written) do
        framework_globals[compat.len(framework_globals) + 1] = name
      end
    end
  end

  return with_llx_unloaded(function()
    for _, name in ipairs(framework_globals) do
      _G[name] = nil
    end
    local lock = strict.lock_global_table()
    local loaded, result = pcall(require, 'llx.unit')
    getmetatable(lock).__close(lock)
    return loaded, result
  end)
end

-- Requires `module_name` from scratch while reading a name the global
-- table does not hold raises, as it does in a host that locks its
-- global table against reads as well as writes. Returns true, or false
-- and the error it raised.
local function require_with_missing_globals_refused(module_name)
  return with_llx_unloaded(function()
    local metatable = getmetatable(_G)
    local refusing = {}
    for key, value in compat.pairs(metatable or {}) do
      refusing[key] = value
    end
    refusing.__index = function(_, name)
      error("undefined global '" .. tostring(name) .. "'", 2)
    end
    setmetatable(_G, refusing)
    local loaded, result = pcall(require, module_name)
    setmetatable(_G, metatable)
    return loaded, result
  end)
end

describe('module global hygiene', function()
  it('should leave no unit framework class in the global table',
      function()
    for _, name in ipairs({'Mock', 'TestLogger', 'HierarchicalLogger'}) do
      expect(rawget(_G, name)).to.be_nil()
    end
  end)

  it('should still export the mock API from llx.unit', function()
    expect(unit.Mock).to_not.be_nil()
    expect(unit.spy_on).to_not.be_nil()
    expect(unit.restore_all_spies).to_not.be_nil()
  end)

  it('should still export both loggers from llx.unit.test_logger',
      function()
    local test_logger = require 'llx.unit.test_logger'
    expect(test_logger.TestLogger).to_not.be_nil()
    expect(test_logger.HierarchicalLogger).to_not.be_nil()
  end)

  it('should find the module list in the rockspec', function()
    local paths, names = shipped_modules()
    expect(paths).to_not.be_nil()
    expect(#(names or {})).to.be_greater_than(0)
  end)

  it('should write no global from any module the rockspec ships',
      function()
    local paths, names = shipped_modules()
    expect(paths).to_not.be_nil()
    local leaks = {}
    for _, name in ipairs(names or {}) do
      if not GLOBAL_INSTALLING_MODULES[name] and loads_here(name) then
        local written, why_not =
          globals_written_by(name, (paths or {})[name])
        if not written then
          leaks[compat.len(leaks) + 1] = name .. ' did not run: ' .. why_not
        elseif compat.len(written) > 0 then
          leaks[compat.len(leaks) + 1] =
            name .. ' wrote ' .. table.concat(written, ', ')
        end
      end
    end
    expect(table.concat(leaks, '; ')).to.be_equal_to('')
  end)

  it('should have an exempt module write exactly the globals it is '
      .. 'named for', function()
    local paths = shipped_modules()
    expect(paths).to_not.be_nil()
    for name, installed in compat.pairs(GLOBAL_INSTALLING_MODULES) do
      expect((paths or {})[name]).to_not.be_nil()
      local written, why_not = globals_written_by(name, (paths or {})[name])
      expect(why_not or '').to.be_equal_to('')
      expect(table.concat(written or {}, ', '))
        .to.be_equal_to(table.concat(installed, ', '))
    end
  end)
end)

describe('loading with the global table locked', function()
  it('should require llx.unit', function()
    local paths = shipped_modules()
    expect(paths).to_not.be_nil()
    local loaded, load_error = require_unit_under_lock(paths or {})
    expect(load_error or '').to.be_equal_to('')
    expect(loaded).to.be_true()
  end)

  it('should require llx with reads of missing globals refused', function()
    local loaded, load_error = require_with_missing_globals_refused('llx')
    expect(load_error or '').to.be_equal_to('')
    expect(loaded).to.be_true()
  end)

  it('should require llx.unit with reads of missing globals refused',
      function()
    local loaded, load_error =
      require_with_missing_globals_refused('llx.unit')
    expect(load_error or '').to.be_equal_to('')
    expect(loaded).to.be_true()
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end

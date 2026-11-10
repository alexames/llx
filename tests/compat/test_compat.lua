-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

local llx = require 'llx'
local compat = require 'llx.compat'
local unit = require 'llx.unit'

local _ENV = unit.create_test_env(_ENV)

-- A global table that raises on a name it does not hold, as a host
-- that locks its global table makes it, reading through to _G for the
-- names it does hold.
local function refusing_environment(fields)
  local environment = fields or {}
  return setmetatable(environment, {
    __index = function(_, name)
      local value = _G[name]
      if value == nil then
        error("undefined global '" .. tostring(name) .. "'", 2)
      end
      return value
    end,
  })
end

-- Compiles `source` with `environment` as its globals.
local function chunk_in(source, environment)
  return assert(compat.load(source, '=' .. environment.label, 't',
                            environment))
end

describe('compat.environment_of', function()
  -- Each chunk keeps the answer in a local before returning it, so the
  -- call into environment_of and the call into the chunk are never in
  -- tail position, which would drop a frame and shift the levels.
  local probe_source = [[
    local compat, level = ...
    local environment = compat.environment_of(level)
    return environment
  ]]
  local caller_source = [[
    local probe, compat, level = ...
    local environment = probe(compat, level)
    return environment
  ]]

  it('should answer the calling function at level 1', function()
    local probe_env = {label = 'probe'}
    local caller_env = {label = 'caller'}
    local probe = chunk_in(probe_source, probe_env)
    local caller = chunk_in(caller_source, caller_env)
    expect(caller(probe, compat, 1)).to.be_equal_to(probe_env)
  end)

  it("should answer the calling function's caller at level 2", function()
    local probe_env = {label = 'probe'}
    local caller_env = {label = 'caller'}
    local probe = chunk_in(probe_source, probe_env)
    local caller = chunk_in(caller_source, caller_env)
    expect(caller(probe, compat, 2)).to.be_equal_to(caller_env)
  end)

  it('should answer through a global table that refuses missing names',
      function()
    local probe_env = refusing_environment({label = 'probe'})
    local caller_env = refusing_environment({label = 'caller'})
    local probe = chunk_in(probe_source, probe_env)
    local caller = chunk_in(caller_source, caller_env)
    expect(caller(probe, compat, 1)).to.be_equal_to(probe_env)
    expect(caller(probe, compat, 2)).to.be_equal_to(caller_env)
  end)
end)

describe('compat.defining_environment', function()
  local source = [[
    local compat = ...
    local environment = compat.defining_environment(function()
      return _ENV
    end)
    return environment
  ]]

  it('should answer the environment of the defining chunk', function()
    local chunk_env = {label = 'chunk'}
    expect(chunk_in(source, chunk_env)(compat)).to.be_equal_to(chunk_env)
  end)

  it('should answer through a global table that refuses missing names',
      function()
    local chunk_env = refusing_environment({label = 'chunk'})
    expect(chunk_in(source, chunk_env)(compat)).to.be_equal_to(chunk_env)
  end)
end)

-- tests/support/host_globals.lua, found from this file's own path.
local function host_globals_path()
  local source = debug.getinfo(1, 'S').source
  local path = source:match('^@(.*)$') or source
  return (path:match('^(.*[/\\])') or '') .. '../support/host_globals.lua'
end

local host_globals = dofile(host_globals_path())

-- The interpreter as this suite's own plain global table reports it.
local RUNNING_LUAJIT = type(rawget(_G, 'jit')) == 'table'

-- Requires `name` in a new world built with `options`, raising what the
-- require raised.
local function require_in_world(options, name)
  local world = host_globals.new(options)
  local ok, result = host_globals.require(world, name)
  if not ok then error(tostring(result), 0) end
  return result, world
end

local WORLDS = {
  {label = 'with the debug library', options = {}},
  {label = 'in a sandbox without the debug library',
   options = {sandbox = true}},
  {label = 'in a sandbox without the global jit',
   options = {sandbox = true, hide_jit = true}},
}

describe('llx.compat under a locked global table', function()
  it('should answer the luajit flag the plain global table answers',
      function()
    expect(compat.luajit).to.be_equal_to(RUNNING_LUAJIT)
  end)

  for _, world in ipairs(WORLDS) do
    describe(world.label, function()
      it("should load the running interpreter's layer", function()
        local world_compat = require_in_world(world.options, 'llx.compat')
        expect(world_compat.layer).to.be_equal_to(compat.layer)
        expect(world_compat.luajit).to.be_equal_to(RUNNING_LUAJIT)
      end)

      it('should load all of llx', function()
        local loaded = require_in_world(world.options, 'llx')
        expect(loaded.class).to_not.be_nil()
      end)

      it('should honour __pairs', function()
        local world_compat = require_in_world(world.options, 'llx.compat')
        local object = setmetatable({}, {
          __pairs = function()
            return next, {answer = 42}, nil
          end,
        })
        local seen = {}
        for key, value in world_compat.pairs(object) do
          seen[key] = value
        end
        expect(seen.answer).to.be_equal_to(42)
      end)
    end)
  end

  it('should count parameters with the debug library', function()
    local world_compat = require_in_world({}, 'llx.compat')
    local count, variadic =
        world_compat.function_parameters(function(a, b, ...) end)
    expect(count).to.be_equal_to(2)
    expect(variadic).to.be_true()
  end)

  it('should report the debug library only where the world has it',
      function()
    local with_debug = require_in_world({}, 'llx.compat')
    local without_debug = require_in_world({sandbox = true}, 'llx.compat')
    expect(with_debug.debug_library).to.be_equal_to(debug)
    expect(without_debug.debug_library).to.be_nil()
  end)

  it('should leave the loaders out where the world has none', function()
    local world_compat = require_in_world({sandbox = true}, 'llx.compat')
    expect(world_compat.load).to.be_nil()
    expect(world_compat.loadfile).to.be_nil()
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end

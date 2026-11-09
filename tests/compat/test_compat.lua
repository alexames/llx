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

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end

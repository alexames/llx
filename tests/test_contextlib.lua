local unit = require 'llx.unit'
local llx = require 'llx'
local contextlib = require 'llx.contextlib'
local with = contextlib.with

_ENV = unit.create_test_env(_ENV)

-- Helper to build a resource with a :close method that records its
-- invocation count and the error (if any) passed to it.
local function make_resource()
  local r = {closed = 0, last_error = nil}
  function r:close(err)
    self.closed = self.closed + 1
    self.last_error = err
  end
  return r
end

-- Helper for a resource that closes via __close metamethod instead.
local function make_meta_resource()
  local r = {closed = 0, last_error = nil}
  return setmetatable(r, {
    __close = function(self, err)
      self.closed = self.closed + 1
      self.last_error = err
    end,
  })
end

describe('with', function()
  describe('normal flow', function()
    it('should run fn with the resource', function()
      local r = make_resource()
      local seen = nil
      with(r, function(res) seen = res end)
      expect(seen).to.be_equal_to(r)
    end)

    it('should close the resource after fn returns', function()
      local r = make_resource()
      with(r, function() end)
      expect(r.closed).to.be_equal_to(1)
    end)

    it('should return fn return values', function()
      local r = make_resource()
      local result = with(r, function(res) return 'a', 'b' end)
      -- The first return value is what we check directly.
      expect(result).to.be_equal_to('a')
    end)

    it('should return multiple values from fn', function()
      local r = make_resource()
      local a, b, c = with(r, function() return 1, 2, 3 end)
      expect(a).to.be_equal_to(1)
      expect(b).to.be_equal_to(2)
      expect(c).to.be_equal_to(3)
    end)
  end)

  describe('error flow', function()
    it('should still close the resource if fn raises', function()
      local r = make_resource()
      pcall(function()
        with(r, function() error('oops') end)
      end)
      expect(r.closed).to.be_equal_to(1)
    end)

    it('should re-raise the fn error after cleanup', function()
      local r = make_resource()
      local ok, err = pcall(function()
        with(r, function() error('boom') end)
      end)
      expect(ok).to.be_false()
      expect(tostring(err):find('boom', 1, true)).to_not.be_nil()
    end)

    it('should re-raise the fn error (exception object)', function()
      local r = make_resource()
      local exceptions = llx.exceptions
      local ok, err = pcall(function()
        with(r, function() error(exceptions.ValueException('bad')) end)
      end)
      expect(ok).to.be_false()
      expect(err.what).to.be_equal_to('bad')
    end)
  end)

  describe('__close metatable form', function()
    it('should prefer __close over :close', function()
      local r = make_meta_resource()
      with(r, function() end)
      expect(r.closed).to.be_equal_to(1)
    end)

    it('should pass the error to __close on raise', function()
      local r = make_meta_resource()
      pcall(function()
        with(r, function() error('marker') end)
      end)
      expect(r.last_error).to_not.be_nil()
      expect(tostring(r.last_error):find('marker', 1, true)).to_not.be_nil()
    end)
  end)

  describe('resource without cleanup', function()
    it('should run fn but skip cleanup when no close method', function()
      local r = {}  -- no :close, no __close
      local seen = nil
      with(r, function(res) seen = res end)
      expect(seen).to.be_equal_to(r)
      -- Nothing to assert about cleanup; just confirm no error.
    end)
  end)

  describe('input validation', function()
    it('should error when fn is not a function', function()
      expect(function() with({}, 'not_a_function') end).to.throw()
    end)
  end)
end)

describe('closing', function()
  it('wraps a :close-able value for use as <close>', function()
    -- <close> is a Lua 5.4+ feature. Compile the body at runtime so this file
    -- still parses on Lua 5.3; skip the assertion where <close> is absent.
    local r = make_resource()
    local body = load([[
      local contextlib, expect, r = ...
      do
        local wrapped <close> = contextlib.closing(r)
      end  -- scope exit triggers __close
      expect(r.closed).to.be_equal_to(1)
    ]])
    if not body then return end  -- Lua < 5.4: <close> unsupported
    body(contextlib, expect, r)
  end)

  it('proxies field reads to the inner resource via __index', function()
    local r = make_resource()
    r.value = 42
    local wrapped = contextlib.closing(r)
    expect(wrapped.value).to.be_equal_to(42)
  end)

  it('rejects values without a :close method', function()
    expect(function() contextlib.closing({}) end).to.throw()
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

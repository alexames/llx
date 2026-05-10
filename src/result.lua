-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Sum types for non-exceptional control flow.
--
-- Result wraps a value-or-error: Ok(value) for success, Err(error)
-- for failure. Option wraps a maybe-value: Some(value) when present,
-- None when absent. Both complement the existing exception system
-- by letting code thread errors and absent values through without
-- pcall/error.
--
-- All four constructors return immutable instances with structural
-- equality, value-based hashing, and the standard transformer
-- methods (map, and_then, or_else, unwrap, unwrap_or).
-- @module llx.result

local class_module = require 'llx.class'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class

-- ---------------------------------------------------------------------------
-- Result: Ok(value) or Err(error_value).
-- ---------------------------------------------------------------------------

Result = class 'Result' {
  __new = function(kind, value)
    return {_kind = kind, _value = value}
  end,

  __init = function(self) end,

  is_ok = function(self) return self._kind == 'ok' end,
  is_err = function(self) return self._kind == 'err' end,

  -- Returns the wrapped value or raises if Err.
  unwrap = function(self)
    if self._kind == 'ok' then return self._value end
    error('Result.unwrap on Err: ' .. tostring(self._value), 2)
  end,

  -- Returns the wrapped value or default if Err.
  unwrap_or = function(self, default)
    if self._kind == 'ok' then return self._value end
    return default
  end,

  -- Returns the error value or raises if Ok.
  unwrap_err = function(self)
    if self._kind == 'err' then return self._value end
    error('Result.unwrap_err on Ok', 2)
  end,

  -- Transforms the wrapped value if Ok; passes through if Err.
  map = function(self, fn)
    if self._kind == 'ok' then return Ok(fn(self._value)) end
    return self
  end,

  -- Transforms the error value if Err; passes through if Ok.
  map_err = function(self, fn)
    if self._kind == 'err' then return Err(fn(self._value)) end
    return self
  end,

  -- Monadic bind on Ok: fn must return a Result. Passes through Err.
  and_then = function(self, fn)
    if self._kind == 'ok' then return fn(self._value) end
    return self
  end,

  -- Monadic bind on Err: fn must return a Result. Passes through Ok.
  or_else = function(self, fn)
    if self._kind == 'err' then return fn(self._value) end
    return self
  end,

  __eq = function(self, other)
    return self._kind == other._kind and self._value == other._value
  end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    result = hash.hash_string('Result.' .. self._kind, result)
    result = hash.hash_value(self._value, result)
    return result
  end,

  __tostring = function(self)
    if self._kind == 'ok' then
      return 'Ok(' .. tostring(self._value) .. ')'
    end
    return 'Err(' .. tostring(self._value) .. ')'
  end,
}

function Ok(value) return Result('ok', value) end
function Err(value) return Result('err', value) end

-- ---------------------------------------------------------------------------
-- Option: Some(value) or None.
-- ---------------------------------------------------------------------------

Option = class 'Option' {
  __new = function(kind, value)
    return {_kind = kind, _value = value}
  end,

  __init = function(self) end,

  is_some = function(self) return self._kind == 'some' end,
  is_none = function(self) return self._kind == 'none' end,

  unwrap = function(self)
    if self._kind == 'some' then return self._value end
    error('Option.unwrap on None', 2)
  end,

  unwrap_or = function(self, default)
    if self._kind == 'some' then return self._value end
    return default
  end,

  -- Transforms the wrapped value if Some; passes through if None.
  map = function(self, fn)
    if self._kind == 'some' then return Some(fn(self._value)) end
    return self
  end,

  -- Monadic bind: fn must return an Option. Passes through None.
  and_then = function(self, fn)
    if self._kind == 'some' then return fn(self._value) end
    return self
  end,

  -- Returns self if Some, else fn() (which must return an Option).
  or_else = function(self, fn)
    if self._kind == 'none' then return fn() end
    return self
  end,

  -- Convert to a Result, supplying an err for None.
  ok_or = function(self, err_value)
    if self._kind == 'some' then return Ok(self._value) end
    return Err(err_value)
  end,

  __eq = function(self, other)
    if self._kind ~= other._kind then return false end
    return self._value == other._value
  end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    result = hash.hash_string('Option.' .. self._kind, result)
    if self._kind == 'some' then
      result = hash.hash_value(self._value, result)
    end
    return result
  end,

  __tostring = function(self)
    if self._kind == 'some' then
      return 'Some(' .. tostring(self._value) .. ')'
    end
    return 'None'
  end,
}

function Some(value) return Option('some', value) end

-- None is a value, not a function: there's only one None per
-- module instance, much like Python's None or Rust's NoneType.
-- Note: this means equality between None values from different
-- module loads is not guaranteed to use object identity, but
-- __eq compares by kind so it still works correctly.
None = Option('none', nil)

return _M

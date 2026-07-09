-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local check_arguments_module = require 'llx.check_arguments'
local class_module = require 'llx.class'
local core = require 'llx.core'
local decorator = require 'llx.decorator'
local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'
local isinstance_module = require 'llx.isinstance'
local matchers = require 'llx.types.matchers'

local _ENV, _M = environment.create_module_environment()

local check_arguments = check_arguments_module.check_arguments
local check_returns_exact = check_arguments_module.check_returns_exact
local class = class_module.class
local Decorator = decorator.Decorator
local InvalidArgumentException = exceptions.InvalidArgumentException
local OverloadResolutionException =
    exceptions.OverloadResolutionException
local is_callable = core.is_callable
local isinstance = isinstance_module.isinstance
local enter_type_var_scope = matchers.enter_type_var_scope
local exit_type_var_scope = matchers.exit_type_var_scope

local function type_name_of(t)
  -- String type names (and the VARARG '...' marker) are their own
  -- description. The explicit type check matters: llx extends the
  -- string library, so every Lua string exposes __name == 'String'
  -- and the generic branch would render all of them as 'String'.
  if type(t) == 'string' then
    return t
  end
  return t and (t.__name or tostring(t)) or 'nil'
end

-- Compact one-line description of a declared signature, e.g.
-- '(Integer, Integer) -> (Integer)'. Used by Overload's dispatch
-- failure message and __tostring; entries may be type matchers,
-- classes, string type names, or the VARARG ('...') marker.
local function describe_signature(fn)
  local param_names = {}
  for i, t in ipairs(fn.params) do
    param_names[i] = type_name_of(t)
  end
  local return_names = {}
  for i, t in ipairs(fn.returns) do
    return_names[i] = type_name_of(t)
  end
  return '(' .. table.concat(param_names, ', ') .. ') -> ('
      .. table.concat(return_names, ', ') .. ')'
end

-- The typed-function wrapper produced by the Signature decorator.
-- Exported so that matchers (e.g. types.matchers.Callable) can
-- recognize wrapped functions and inspect their declared signature.
Function = class 'Function' {
  __new = function(args)
    return args
  end,

  __call = function(self, ...)
    local scope = self:check_preconditions(table.pack(...))
    local results = table.pack(self.func(...))
    self:check_postconditions(results, scope)
    return table.unpack(results, 1, results.n)
  end,

  -- table.pack supplies the exact value count in `n`; # is used as a
  -- fallback so plain list tables still work when these methods are
  -- called directly. A trailing '...' entry in params or returns
  -- makes the signature variadic (see check_returns_exact).
  --
  -- Generic signatures: each precondition check runs inside a fresh
  -- TypeVar binding scope (see llx.types.matchers), so a TypeVar in
  -- params binds to the type of the first value checked against it
  -- and later occurrences must be consistent. The scope is returned
  -- so the caller can hand it to check_postconditions, which
  -- re-enters the *same* scope; that is what correlates parameter and
  -- return types through a shared TypeVar. The scope is entered only
  -- for the duration of the synchronous check (never across the
  -- wrapped function's body), which keeps recursion and coroutines
  -- safe, and it is always exited -- the pcall re-raise below
  -- preserves the exception object unchanged (llx exceptions capture
  -- their location at construction, so the reported position
  -- survives; only the raw traceback gains the pcall frame).
  check_preconditions = function(self, arguments)
    local scope = enter_type_var_scope()
    local ok, err = pcall(check_returns_exact, self.params, arguments,
                          arguments.n or #arguments)
    exit_type_var_scope()
    if not ok then
      error(err, 0)
    end
    return scope
  end,

  check_postconditions = function(self, results, scope)
    enter_type_var_scope(scope)
    local ok, err = pcall(check_returns_exact, self.returns, results,
                          results.n or #results)
    exit_type_var_scope()
    if not ok then
      error(err, 0)
    end
  end,

  __tostring = function(self)
    local function_format_str = [=[Function{
  params={%s},
  returns={%s},
  func=function(...) --[[ ... ]] end,
}]=]
    return function_format_str:format(
      table.concat(self.params, ', '), table.concat(self.returns, ', '))
  end
}

Signature = class 'Signature' : extends(Decorator) {
  __new = function(args)
    return args
  end,

  decorate = function(self, t, k, v)
    return t, k, Function{params=self.params,
                          returns=self.returns,
                          func=v}
  end,
}

-- Binding operator: `Signature{...} .. fn` wraps fn in a Function
-- carrying the declared signature -- the same wrapper `decorate`
-- produces, but usable outside the class-decorator syntax. This is
-- the declaration form Overload builds on. Defined after the class so
-- the handler can identify which operand is the Signature (Lua calls
-- the metamethod with the operands in source order, so a callable
-- table on the left would otherwise land in `self`).
Signature.__concat = function(a, b)
  local signature, func
  if isinstance(a, Signature) then
    signature, func = a, b
  else
    signature, func = b, a
  end
  if not is_callable(func) then
    error('Signature: expected a callable to bind, got '
        .. type(func), 2)
  end
  return Function{params=signature.params,
                  returns=signature.returns,
                  func=func}
end

-- An ordered overload set: one callable value, several Signature
-- declarations, dispatched at call time -- the runtime analog of
-- mypy's @overload. Declared as a list of signature-bound functions:
--
--     local describe = Overload{
--       Signature{params={Integer}, returns={String}}
--           .. function(n) return 'int ' .. n end,
--       Signature{params={String}, returns={String}}
--           .. function(s) return 'str ' .. s end,
--     }
--
-- Dispatch is first-match-wins: the candidates' preconditions are
-- checked in declaration order and the first declaration that accepts
-- the arguments is called; its postconditions are then enforced as
-- usual. Declare the most specific signature first -- a broad
-- candidate (e.g. one taking Any, or a variadic '...') placed early
-- shadows every later candidate it overlaps. Each precondition check
-- is O(params), so dispatch costs O(candidates * params) per call;
-- fine for the expected handful of overloads, but keep sets small on
-- hot paths.
--
-- Only argument-mismatch failures (InvalidArgumentException and its
-- subclasses, which is also how arity errors are reported) count as
-- "this candidate does not match"; any other error raised while
-- checking (e.g. the ValueException for a malformed non-trailing
-- '...') propagates immediately. When no candidate accepts the call,
-- an OverloadResolutionException (an ExceptionGroup) is raised
-- listing every candidate signature with its rejection reason.
--
-- In a class definition an Overload is assigned directly to its key,
-- with no `|` decorator (the decorator syntax carries one value per
-- key, so a multi-declaration set cannot be expressed through it):
--
--     local Point = class 'Point' {
--       move = Overload{
--         Signature{params={'Point', Integer, Integer}, returns={}}
--             .. function(self, x, y) ... end,
--         Signature{params={'Point', 'Point'}, returns={}}
--             .. function(self, other) ... end,
--       },
--     }
--
-- Method-call syntax works unchanged (`p:move(1, 2)` passes p as the
-- first argument, dispatched like any other).
--
-- The declaration list is exposed as the `overloads` field so the
-- type system can introspect it: isinstance against types.Callable
-- and llx.is_subtype.signature_compatible treat an overload set as
-- compatible when any declaration is compatible (see those modules).
Overload = class 'Overload' {
  __new = function(declarations)
    if type(declarations) ~= 'table' or #declarations == 0 then
      error('Overload: expected a non-empty list of signature-bound '
          .. 'functions (Signature{...} .. fn)', 3)
    end
    for i, fn in ipairs(declarations) do
      if not isinstance(fn, Function) then
        error(string.format(
            'Overload: entry %d is not a signature-bound function; '
            .. 'bind each candidate with Signature{...} .. fn', i), 3)
      end
    end
    return {overloads = declarations}
  end,

  __call = function(self, ...)
    local arguments = table.pack(...)
    local failures = {}
    for _, fn in ipairs(self.overloads) do
      -- On success the pcall yields the candidate's TypeVar binding
      -- scope (each candidate opens its own, so a rejected
      -- candidate's partial bindings never leak into the next);
      -- passing it to check_postconditions correlates the winning
      -- declaration's parameter and return types through any shared
      -- TypeVars. On failure it yields the rejection exception.
      local ok, scope_or_err = pcall(fn.check_preconditions, fn,
                                     arguments)
      if ok then
        local results = table.pack(fn.func(...))
        fn:check_postconditions(results, scope_or_err)
        return table.unpack(results, 1, results.n)
      end
      if not isinstance(scope_or_err, InvalidArgumentException) then
        error(scope_or_err, 0)
      end
      failures[#failures + 1] = scope_or_err
    end
    local candidates = {}
    for i, fn in ipairs(self.overloads) do
      candidates[i] = describe_signature(fn)
    end
    error(OverloadResolutionException(candidates, failures, 2))
  end,

  __tostring = function(self)
    local candidates = {}
    for i, fn in ipairs(self.overloads) do
      candidates[i] = '  ' .. describe_signature(fn)
    end
    return 'Overload{\n' .. table.concat(candidates, ',\n') .. ',\n}'
  end,
}

return _M

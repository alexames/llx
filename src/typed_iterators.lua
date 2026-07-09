-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

--- Typed iterators and typed coroutine generators: opt-in runtime
-- enforcement of per-step yield types, coroutine send types, and
-- final return types -- the enforcement half of the runtime analogs
-- of mypy's Iterator[T] and Generator[YieldType, SendType,
-- ReturnType]. The matching half (the Iterator(...) and Generator{}
-- matchers) lives in llx.types.matchers.
--
-- Per-step checking costs O(yield arity) on every iteration of every
-- loop, so it is never imposed by a matcher: only values explicitly
-- wrapped here are checked.
--
-- Scope (first iteration; deliberate, documented choices):
--
-- - Only the closure form of Lua's iterator protocol is wrapped: a
--   single iterator function carrying its own state, as returned by
--   llx.functional's combinators. The stateless triplet form
--   (`iterator, state, control`, e.g. ipairs) is not wrapped; wrap
--   the closure produced by binding the state instead. Generic-for
--   still works with wrapped iterators because the wrapper forwards
--   the (state, control) arguments it receives.
-- - Following Lua's generic-for convention, a step whose first value
--   is nil (or that produces no values) signals completion and is
--   passed through unchecked; the declared yield types apply to every
--   other step.

local check_arguments_module = require 'llx.check_arguments'
local class_module = require 'llx.class'
local core = require 'llx.core'
local decorator = require 'llx.decorator'
local environment = require 'llx.environment'
local isinstance_module = require 'llx.isinstance'
local matchers = require 'llx.types.matchers'

local _ENV, _M = environment.create_module_environment()

local check_returns_exact = check_arguments_module.check_returns_exact
local class = class_module.class
local Decorator = decorator.Decorator
local is_callable = core.is_callable
local isinstance = isinstance_module.isinstance
local enter_type_var_scope = matchers.enter_type_var_scope
local exit_type_var_scope = matchers.exit_type_var_scope

-- Compact comma-separated description of a declared type list;
-- entries may be type matchers, classes, string type names, or the
-- VARARG ('...') marker. The explicit string check matters: llx
-- extends the string library, so every Lua string exposes
-- __name == 'String' and the generic branch would render all of
-- them as 'String'.
local function describe_types(types)
  local names = {}
  for i, t in ipairs(types) do
    if type(t) == 'string' then
      names[i] = t
    else
      names[i] = t and (t.__name or tostring(t)) or 'nil'
    end
  end
  return table.concat(names, ', ')
end

-- Checks one tuple of values crossing a typed boundary against a
-- declared type list, inside a fresh TypeVar binding scope (see
-- llx.types.matchers): a TypeVar appearing more than once in the
-- list must bind consistently within the tuple, but each boundary
-- crossing (each iterator step, send, yield, or return) binds
-- independently. The scope is always exited, and the pcall re-raise
-- preserves the exception object unchanged (llx exceptions capture
-- their location at construction).
local function check_boundary(expected_types, values)
  enter_type_var_scope()
  local ok, err = pcall(check_returns_exact, expected_types, values,
                        values.n or #values)
  exit_type_var_scope()
  if not ok then
    error(err, 0)
  end
end

--- The typed-iterator wrapper produced by the Yields declaration.
--
-- Instances are callable and follow the closure iterator protocol:
-- generic-for's (state, control) arguments are forwarded to the
-- underlying closure, and every non-final step's values are checked
-- against the declared `yields` list with exact-count semantics (a
-- trailing '...' entry declares an unchecked variadic tail, exactly
-- as in llx.signature declarations). Exported so that matchers
-- (types.matchers.Iterator) can recognize wrapped iterators and
-- inspect their declared yield types.
IteratorFunction = class 'IteratorFunction' {
  __new = function(args)
    return args
  end,

  __call = function(self, state, control)
    local values = table.pack(self.func(state, control))
    if values.n == 0 or values[1] == nil then
      -- Generic-for's termination signal; not a yielded tuple.
      return table.unpack(values, 1, values.n)
    end
    check_boundary(self.yields, values)
    return table.unpack(values, 1, values.n)
  end,

  __tostring = function(self)
    return 'IteratorFunction{yields={'
        .. describe_types(self.yields) .. '}}'
  end,
}

--- Declaration form for typed iterators, mirroring Signature:
--
--     local it = Yields{Integer, String} .. some_iterator_closure
--
-- binds the closure to an IteratorFunction that checks each yielded
-- (Integer, String) step. As a class-member decorator
-- (['step' | Yields{...}]) it wraps the member function itself as
-- the iterator closure; note that most members are iterator
-- *factories* (they return an iterator), for which the binding form
-- inside the factory is the right tool.
Yields = class 'Yields' : extends(Decorator) {
  __new = function(yield_types)
    if type(yield_types) ~= 'table' then
      error('Yields: expected a list of yield types', 3)
    end
    return {yields = yield_types}
  end,

  decorate = function(self, t, k, v)
    return t, k, IteratorFunction{yields = self.yields, func = v}
  end,
}

-- Binding operator: `Yields{...} .. fn` wraps fn in an
-- IteratorFunction carrying the declared yield types -- the same
-- wrapper `decorate` produces, but usable outside the
-- class-decorator syntax. Defined after the class so the handler can
-- identify which operand is the declaration (Lua calls the
-- metamethod with the operands in source order, so a callable table
-- on the left would otherwise land in `self`).
Yields.__concat = function(a, b)
  local declaration, func
  if isinstance(a, Yields) then
    declaration, func = a, b
  else
    declaration, func = b, a
  end
  if not is_callable(func) then
    error('Yields: expected a callable to bind, got '
        .. type(func), 2)
  end
  return IteratorFunction{yields = declaration.yields, func = func}
end

--- A running typed coroutine: the checked analog of the function
-- returned by coroutine.wrap, produced by calling a
-- GeneratorFunction. Exported so that matchers
-- (types.matchers.Generator) can recognize typed generators and
-- inspect their declared contract (`yields`, `accepts`, `returns`).
--
-- Boundary checks (each with exact-count semantics; a trailing '...'
-- entry in any list declares an unchecked variadic tail):
--
-- - Values yielded out of the body are checked against `yields` on
--   every resume.
-- - Values returned by the body on completion are checked against
--   `returns` (on the resume that finds the coroutine dead).
-- - Values sent in are checked against `accepts`, but only through
--   the explicit send method: plain calls resume unchecked-in,
--   because Lua's generic-for calls its iterator with (state,
--   control) arguments that are not semantically sends. This is what
--   keeps `for v in gen do ... end` working on a typed generator.
--
-- As with coroutine.wrap, the first resume starts the body (whose
-- arguments were bound when the GeneratorFunction was called);
-- values passed to the first resume are not sends and are ignored by
-- the body. Mirroring Python's just-started generators, send raises
-- if values are passed before the first resume. A generator whose
-- `returns` list declares values is not generic-for terminable
-- (the loop would consume the return values and resume a dead
-- coroutine) -- drive it by explicit calls instead, exactly as with
-- raw coroutine.wrap.
GeneratorInstance = class 'GeneratorInstance' {
  __new = function(args)
    args.started = false
    return args
  end,

  __call = function(self, ...)
    return self:resume(...)
  end,

  -- Sends values into the suspended body (they become the results of
  -- the yield that suspended it), checking them against `accepts`
  -- first. On a just-started generator the body is not yet at a
  -- yield to receive anything, so sending values raises, and a
  -- value-less send simply starts the body (the accepts contract
  -- does not apply, exactly as Python permits only send(None) on a
  -- just-started generator).
  send = function(self, ...)
    if not self.started then
      if select('#', ...) > 0 then
        error('GeneratorInstance: cannot send values to a '
            .. 'just-started generator; resume it once first', 2)
      end
      return self:resume()
    end
    check_boundary(self.accepts, table.pack(...))
    return self:resume(...)
  end,

  -- The shared resume path: forwards values into the coroutine
  -- (unchecked; see send for the checked entry point) and checks
  -- what comes out -- yields while suspended, returns once dead.
  -- Errors raised inside the body propagate unchanged, as with
  -- coroutine.wrap.
  resume = function(self, ...)
    self.started = true
    local results = table.pack(coroutine.resume(self.thread, ...))
    if not results[1] then
      error(results[2], 0)
    end
    local values = table.pack(
        table.unpack(results, 2, results.n))
    if coroutine.status(self.thread) == 'dead' then
      check_boundary(self.returns, values)
    else
      check_boundary(self.yields, values)
    end
    return table.unpack(values, 1, values.n)
  end,

  status = function(self)
    return coroutine.status(self.thread)
  end,
}

--- The typed-coroutine factory produced by the Generates
-- declaration: calling it with the body's arguments creates the
-- coroutine (started lazily, on the first resume, like
-- coroutine.wrap) and returns a GeneratorInstance enforcing the
-- declared contract.
GeneratorFunction = class 'GeneratorFunction' {
  __new = function(args)
    return args
  end,

  __call = function(self, ...)
    local func = self.func
    local args = table.pack(...)
    local thread = coroutine.create(function()
      return func(table.unpack(args, 1, args.n))
    end)
    return GeneratorInstance{
      thread = thread,
      yields = self.yields,
      accepts = self.accepts,
      returns = self.returns,
    }
  end,

  __tostring = function(self)
    return 'GeneratorFunction{yields={'
        .. describe_types(self.yields) .. '}, accepts={'
        .. describe_types(self.accepts) .. '}, returns={'
        .. describe_types(self.returns) .. '}}'
  end,
}

--- Declaration form for typed coroutines, the typed sibling of
-- llx.coroutine.wrap:
--
--     local gen = Generates{yields = {Integer},
--                           accepts = {String},
--                           returns = {}} .. function(n)
--       for i = 1, n do
--         local sent = coroutine.yield(i)
--       end
--     end
--     local instance = gen(3)
--     for v in instance do ... end
--
-- Missing contract lists default to empty (yields nothing, accepts
-- nothing, returns nothing); declare '...' tails to leave a boundary
-- unchecked. As a class-member decorator (['gen' | Generates{...}])
-- it wraps the member function as the coroutine body, so calling the
-- member returns a fresh GeneratorInstance per call, exactly like
-- llx.coroutine.wrap but checked.
Generates = class 'Generates' : extends(Decorator) {
  __new = function(contract)
    if type(contract) ~= 'table' then
      error('Generates: expected a contract table with optional '
          .. 'yields, accepts, and returns lists', 3)
    end
    for key in pairs(contract) do
      if key ~= 'yields' and key ~= 'accepts' and key ~= 'returns' then
        error("Generates: unknown contract key '" .. tostring(key)
            .. "'", 3)
      end
    end
    return {
      yields = contract.yields or {},
      accepts = contract.accepts or {},
      returns = contract.returns or {},
    }
  end,

  decorate = function(self, t, k, v)
    return t, k, GeneratorFunction{yields = self.yields,
                                   accepts = self.accepts,
                                   returns = self.returns,
                                   func = v}
  end,
}

-- Binding operator: `Generates{...} .. fn` wraps fn in a
-- GeneratorFunction carrying the declared contract; see
-- Yields.__concat above for the operand-order handling.
Generates.__concat = function(a, b)
  local declaration, func
  if isinstance(a, Generates) then
    declaration, func = a, b
  else
    declaration, func = b, a
  end
  if not is_callable(func) then
    error('Generates: expected a callable to bind, got '
        .. type(func), 2)
  end
  return GeneratorFunction{yields = declaration.yields,
                           accepts = declaration.accepts,
                           returns = declaration.returns,
                           func = func}
end

return _M

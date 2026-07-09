-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local check_arguments_module = require 'llx.check_arguments'
local class_module = require 'llx.class'
local decorator = require 'llx.decorator'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local check_arguments = check_arguments_module.check_arguments
local check_returns_exact = check_arguments_module.check_returns_exact
local class = class_module.class
local Decorator = decorator.Decorator

-- The typed-function wrapper produced by the Signature decorator.
-- Exported so that matchers (e.g. types.matchers.Callable) can
-- recognize wrapped functions and inspect their declared signature.
Function = class 'Function' {
  __new = function(args)
    return args
  end,

  __call = function(self, ...)
    self:check_preconditions(table.pack(...))
    local results = table.pack(self.func(...))
    self:check_postconditions(results)
    return table.unpack(results, 1, results.n)
  end,

  -- table.pack supplies the exact value count in `n`; # is used as a
  -- fallback so plain list tables still work when these methods are
  -- called directly. A trailing '...' entry in params or returns
  -- makes the signature variadic (see check_returns_exact).
  check_preconditions = function(self, arguments)
    check_returns_exact(self.params, arguments, arguments.n or #arguments)
  end,

  check_postconditions = function(self, results)
    check_returns_exact(self.returns, results, results.n or #results)
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

return _M

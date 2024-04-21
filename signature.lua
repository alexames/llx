-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local check_arguments_module = require 'llx/check_arguments'
local class_module = require 'llx/class'
local decorator = require 'llx/decorator'
local environment = require 'llx/environment'

local _ENV, _M = environment.create_module_environment()

local check_arguments = check_arguments_module.check_arguments
local check_returns = check_arguments_module.check_returns
local class = class_module.class
local Decorator = decorator.Decorator

local Function = class 'Function' {
  __new = function(args)
    return args
  end,

  __call = function(self, ...)
    self:check_preconditions({...})
    local results = {self.func(...)}
    self:check_postconditions(results)
    return table.unpack(results)
  end,

  check_preconditions = function(self, arguments)
    check_returns(self.params, arguments)
  end,

  check_postconditions = function(self, results)
    check_returns(self.returns, results)
  end,

  __tostring = function(self)
    print('test')
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

-------------------------------------------------------------------------------

local types = require 'llx/types'
local Integer = types.Integer
local Self = types.Any

local TestClass = class 'TestClass' {
  ['testfunc'
  | Signature{params={'TestClass', Integer, Integer, Integer},
              returns={Integer}}] =
  function(self, a, b, c)
    local sum = a + b + c
    return sum
  end
}

tc = TestClass()

print(tc:testfunc(1, 2, 3))

print(tc.testfunc.params)
print(tc.testfunc.returns)
print(tc.testfunc)
return _M

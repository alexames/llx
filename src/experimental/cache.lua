-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx/src/class' . class
local Decorator = require 'llx/src/decorator' . Decorator
local environment = require 'llx/src/environment'
local HashTable = require 'llx/src/hash_table' . HashTable
local Tuple = require 'llx/src/tuple'. Tuple

local _ENV, _M = environment.create_module_environment()

local cache = class 'cache' : extends(Decorator) {
  __init = function(self, params)
    self.include_self = params and params.include_self
  end,

  decorate = function(self, class_table, name, underlying_function)
    local cache = HashTable{}
    local include_self = self.include_self
    local function wrapped_function(self, ...)
      local key
      if include_self then
        key = Tuple{self, ...}
      else
        key = Tuple{...}
      end
      local result = cache[key]
      if result == nil then
        result = {
          value = underlying_function(self, ...),
        }
        cache[key] = result
      end
      return result.value
    end
    return class_table, name, wrapped_function
  end,
}

-- FibTester = class 'FibTester' {
--   ['fib' | cache{include_self=false}] = function(self, n)
--     print(n)
--     if n < 2 then return n
--     else return self:fib(n-1) + self:fib(n-2)
--     end
--   end,
-- }

-- f = FibTester()
-- print(f:fib(100))

return _M

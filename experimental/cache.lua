-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx/class' . class
local Decorator = require 'llx/decorator' . Decorator
local environment = require 'llx/environment'
local HashTable = require 'llx/hash_table' . HashTable
local Tuple = require 'llx/tuple'. Tuple

local _ENV, _M = environment.create_module_environment()

local Cache = class 'Cache' : extends(Decorator) {
  decorate = function(self, class_table, name, underlying_function)
    local cache = HashTable{}
    local function wrapped_function(...)
      local key = Tuple{...}
      local result = cache[key]
      if result == nil then
        result = {
          value = underlying_function(...),
        }
        cache[key] = result
      end
      return result.value
    end
    return class_table, name, wrapped_function
  end,
}

cache = Cache()

return _M

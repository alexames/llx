--- Utility functions for creating scoped environments.
--
-- This file defines a create_module_environment function, which can be used to
-- help create self contained modules. For example, you might have a module that
-- contains the following:
--
--------------------------------------------------------------------------------
--
-- local environment = require 'llx' . environment
--
-- local _ENV, _M = environment.create_module_environment()
--
-- -- Define a variable in the scoped environment
-- my_variable = 42
--
-- -- Define a function in the scoped environment
-- my_function = function(x, y)
--   return x + y
-- end
--
-- -- Access variables and functions in the scoped environment
-- print(my_variable)  -- Output: 42
-- print(my_function(10, 20))  -- Output: 30
--
-- -- Access global variables
-- _G.global_variable = "Global value"
--
-- -- Access global variable from within the scoped environment
-- print(global_variable)  -- Output: Global value
--
-- -- Access non-existing variable in the scoped environment
-- print(non_existing_variable)  -- Output: nil
--
-- return _M
--------------------------------------------------------------------------------
--
-- Inside the modules, the values can be accessed like normal. However, anything
-- not marked local will end up in the _ENV table, which is returned (and thus
-- exported) at the end.
--
-- Values that were global in the module scope are not accessable from code that
-- includes it unless accessed through the module's returned table. For example:
--
--------------------------------------------------------------------------------
--
-- local module = require 'module'
--
-- -- Attempt to access variables and functions after closing the environment
-- print(my_variable)  -- Output: nil
-- print(my_function)  -- Output: nil
-- print(module.my_variable)  -- Output: 42
-- print(module.my_function(10, 20))  -- Output: 30
--
-- -- Attempt to access global variable after closing the scoped environment
-- print(global_variable)  -- Output: Global value
--
--------------------------------------------------------------------------------

local function make_module_metatable(module)
  return {
    __call = function(self, t)
      local result = {}
      for i, v in ipairs(t) do
        local module_value = rawget(module, v)
        assert(module_value)
        result[i] = module_value
      end
      return table.unpack(result)
    end,

    __index = function(self, k)
      local result = rawget(module, k)
      if result == nil then
        error(string.format("module does not contain field '%s'", k), 2)
      end
      return result
    end,

    __newindex = function(self, k, v)
      error('module tables are locked')
    end,

    __pairs = function(self)
      return next, module, nil
    end,
  }
end

--- Creates a new module environment.
--
-- This function creates a new Lua environment table along with a module table.
-- The module table acts as a container for module variables, while the
-- environment table provides access to both module variables and global
-- variables.
--
-- @return environment The newly created environment table.
-- @return module The module table.
local function create_module_environment()
  local module = {}
  local module_proxy = setmetatable({}, make_module_metatable(module))
  local environment = setmetatable({}, {
    __index = function(self, k)
      local result = rawget(module, k) or _ENV[k]
      if result == nil then
        error(string.format("module does not contain field '%s'", k), 2)
      end
      return result
    end,
    __newindex = function(self, k, v)
      rawset(module, k, v)
    end,
  })

  return environment, module_proxy
end

return {
  create_module_environment=create_module_environment,
  make_module_metatable=make_module_metatable,
}

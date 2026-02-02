--- Utility functions for creating scoped environments.
--
-- This file defines a create_module_environment function, which can be used to
-- help create self contained modules. For example, you might have a module that
-- contains the following:
--
--------------------------------------------------------------------------------
--
-- local llx = require 'llx'
--
-- local _ENV, _M = llx.environment.create_module_environment()
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
local function create_module_environment(using_modules)
  -- The contents module itself. Inside the module, this is populated by the
  -- environment. Outside the module, it is treated as read only by the proxy.
  local module = {}
  local module_proxy = setmetatable({}, make_module_metatable(module))

  -- The using_table is for importing things into the 'global' namespace,
  -- without exporting them to the symbols to the module. This function takes a
  -- list of tables, and performs a shallow copy into the using table so that
  -- the symbols can be used directly without being qualified. In other words,
  -- you can do this:
  --
  --   require 'file_reader_module'
  --   _ENV, _M = llx.environment.create_module_environment{file_reader_module}
  --   -- No need to qualify function call with `file_reader_module.`
  --   read_file('./foo')
  local using_table = {}
  if using_modules then
    for i, using_module in ipairs(using_modules) do
      for k, v in pairs(using_module) do
        assert(using_table[k] == nil,
               string.format('key collision in using statement (%s)', k), 2)
        rawset(using_table, k, v)
      end
    end
  end
  
  local environment = setmetatable({}, {
    __index = function(self, k)
      local result = rawget(module, k) or rawget(using_table, k) or _ENV[k]
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

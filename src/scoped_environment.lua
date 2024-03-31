--- Utility functions for creating scoped environments.
--
-- This file defines a create_environment function, which can be used to help
-- create self contained modules. For example, you might have a module that
-- contains the following:
--
--------------------------------------------------------------------------------
--
-- local scoped_env = require 'scoped_environment'
--
-- module = scoped_env.create_environment()
-- local _ENV <close> = module
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
-- return _ENV
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
-- -- Attempt to access variables and functions after closing the environment
-- print(my_variable)  -- Output: nil (scoped environment is closed)
-- print(my_function)  -- Output: nil (scoped environment is closed)
-- print(module.my_variable)  -- Output: 42
-- print(module.my_function(10, 20))  -- Output: 30
--
-- -- Attempt to access global variable after closing the scoped environment
-- print(global_variable)  -- Output: Global value
--
--------------------------------------------------------------------------------

--- Creates a scoped table with a given index fallback.
--
-- The scoped table uses the __index metamethod to fall back to the given table
-- to find functions or variables. After it's closed, it removes its metatable.
--
-- @param fallback The index fallback table.
-- @return The scoped table with the specified fallback.
local function scoped_table(fallback)
  local t = {}
  return setmetatable(t, {
      --- Closes the scoped table and removes its metatable.
      __close=function() setmetatable(t, nil) end,
      --- Fallback to the given table.
      __index=fallback,
    })
end

--- Creates a new environment with scoped behavior.
--
-- The returned environment will fallback to the global environment to find
-- functions or variables that are global. After it's closed, it removes its
-- metatable.
--
-- @return The new environment with scoped behavior.
local function create_environment()
  return scoped_table(_ENV)
end

return {
  scoped_table=scoped_table,
  create_environment=create_environment,
}
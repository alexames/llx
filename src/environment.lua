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

    __tostring = function(self)
      -- Summarize the public surface so `print(my_module)` shows
      -- something more useful than `table: 0x...`. Internal __X
      -- fields are filtered out.
      local fields = {}
      for k in pairs(module) do
        if type(k) == 'string'
            and not (k:sub(1, 2) == '__') then
          fields[#fields + 1] = k
        end
      end
      table.sort(fields)
      if #fields == 0 then return 'module<empty>' end
      if #fields > 5 then
        return string.format(
          'module<%s, ... (%d total)>',
          table.concat({fields[1], fields[2], fields[3]}, ', '),
          #fields)
      end
      return 'module<' .. table.concat(fields, ', ') .. '>'
    end,

    -- Internal reference: callers like environment.has can reach
    -- the underlying module table without going through __index.
    __module = module,
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

--- Checks whether a module proxy exposes a field, without raising.
-- The proxy's __index raises an error for missing fields (strict
-- mode); has provides the safe alternative.
-- @param module A module proxy produced by create_module_environment
-- @param name The field name to look up
-- @return true iff the field is defined (and non-nil) on the module
local function has(module, name)
  local mt = getmetatable(module)
  if mt == nil or mt.__module == nil then return false end
  return rawget(mt.__module, name) ~= nil
end

--- Wraps a function so the first call prints a one-time deprecation
-- warning to stderr. Subsequent calls pass through silently.
-- @param name The function or symbol name being deprecated
-- @param fn The function to wrap (or any callable)
-- @param message Optional human-readable replacement guidance
-- @return A wrapped function with the same signature as fn
local function deprecated(name, fn, message)
  local warned = false
  return function(...)
    if not warned then
      warned = true
      io.stderr:write(string.format(
        '[DEPRECATED] %s: %s\n',
        tostring(name),
        message or 'this is deprecated and will be removed'))
    end
    return fn(...)
  end
end

return {
  create_module_environment=create_module_environment,
  make_module_metatable=make_module_metatable,
  has=has,
  deprecated=deprecated,
}

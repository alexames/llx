-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local catch = require 'llx.flow_control.catch' . catch
local environment = require 'llx.environment'
local isinstance = require 'llx.isinstance' . isinstance
local Table = require 'llx.types.table' . Table

local _ENV, _M = environment.create_module_environment()

function find_and_handle_exception(try_block, thrown_exception)
  local _, matching_entry =
    Table.ifind_if(try_block, function(i, catcher)
      return isinstance(thrown_exception, catcher.exception)
    end, 2)
  local handler = matching_entry and matching_entry.handler
                  or error
  handler(thrown_exception)
end

-- try {
--   function()
--     readMyFile(...) -- might raise FileNotFoundException()
--   end;
--   catch(FileNotFoundException, function(e)
--     -- Handle file not found
--   end);
--   catch(Any, function(e)
--     -- Handle any other error
--   end);
-- }
function try(try_block)
  local body_function = try_block[1]
  local successful, thrown_exception = pcall(body_function)
  if not successful then
    find_and_handle_exception(try_block, thrown_exception)
  end
end

return _M

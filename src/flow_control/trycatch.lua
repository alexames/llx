-- Copyright 2023 Alexander Ames <Alexander.Ames@gmail.com>

require 'llx/src/types/table'
require 'llx/src/isinstance'
require 'llx/src/flow_control/catch'

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

return 
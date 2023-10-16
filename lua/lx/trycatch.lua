require 'ext/table'

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
  table(try_block)
  local body_function = try_block[1]
  local successful, thrown_exception = pcall(body_function)
  if not successful then
    local _, matching_entry =
      try_block:ifind_if(function(i, catcher)
        return catcher.exception.isinstance(thrown_exception)
      end, 2)
    local handler = matching_entry and matching_entry.handler
                    or error
    handler(thrown_exception)
  end
end

function catch(exception, handler)
  return {exception=exception, handler=handler}
end

return try, catch

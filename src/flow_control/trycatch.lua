-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local catch = require 'llx.flow_control.catch' . catch
local environment = require 'llx.environment'
local getclass = require 'llx.getclass' . getclass
local is_callable = require 'llx.core' . is_callable
local isinstance = require 'llx.isinstance' . isinstance
local Table = require 'llx.types.table' . Table

local _ENV, _M = environment.create_module_environment()

-- Walks a class and its superclass chain looking for a __name equal
-- to expected_name. Classes reach here as class-table proxies; their
-- __superclasses entries are the base-class proxies, so the walk
-- follows the same chain that __isinstance dispatch does, by name.
local function class_name_matches(class_object, expected_name)
  if type(class_object) ~= 'table' then
    return false
  end
  if class_object.__name == expected_name then
    return true
  end
  local superclasses = class_object.__superclasses
  if type(superclasses) ~= 'table' then
    return false
  end
  for _, superclass in ipairs(superclasses) do
    if class_name_matches(superclass, expected_name) then
      return true
    end
  end
  return false
end

-- Decides whether one catch clause handles the thrown value. A
-- string catch type matches by class name: the thrown value's own
-- class or any of its superclasses (#92). Any other value that is
-- not a matcher (a table with a callable __isinstance -- the same
-- shape isinstance itself dispatches on) is treated as non-matching
-- rather than handed to isinstance: this code runs while an
-- exception is already unwinding, and letting isinstance's
-- bad-matcher guard raise here would mask the original exception
-- with a secondary one. catch() already rejects such values at
-- construction time; this check is the backstop for hand-built
-- clause tables that bypass catch().
local function catcher_matches(thrown_exception, catch_type)
  if type(catch_type) == 'string' then
    return class_name_matches(getclass(thrown_exception), catch_type)
  end
  if type(catch_type) ~= 'table'
     or not is_callable(catch_type.__isinstance) then
    return false
  end
  return isinstance(thrown_exception, catch_type)
end

function find_and_handle_exception(try_block, thrown_exception)
  local _, matching_entry =
    Table.ifind_if(try_block, function(i, catcher)
      return type(catcher) == 'table'
         and catcher_matches(thrown_exception, catcher.exception)
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
--   catch('ValueException', function(e)
--     -- Class-name strings match the class or any subclass
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

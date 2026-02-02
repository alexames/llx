-- mock.lua
-- Mock object for call tracking and behavior control
--
-- @module unit.mock

local llx = require 'llx'
local class = llx.class

--- A mock function object.
-- Tracks all calls, allows flexible return values and implementations.
-- Example usage:
--   local mock = Mock()
--   mock:mock_return_value(42)
--   local result = mock('hello', 'world')
--   expect(mock).to.have_been_called_times(1)
--   expect(mock).to.have_been_called_with('hello', 'world')
Mock = class 'Mock' {
  --- Constructor
  -- @param self Mock instance
  -- @param default_return_value Optional default return value for all calls
  __init = function(self, default_return_value)
    self._call_history = {}              -- Array of {args = {...}, return_value = ...}
    self._call_count = 0
    self._default_implementation = nil   -- Function for all calls
    -- Store default return value as table to support multiple return values
    if default_return_value ~= nil then
      self._default_return_value = {default_return_value}
    else
      self._default_return_value = nil
    end
    self._implementation_queue = {}       -- Queue of functions for next calls
    self._return_value_queue = {}         -- Queue of values for next calls
    self._name = nil                     -- Optional name for better error messages
  end;

  --- Set a default return value for all calls
  -- @param self Mock instance
  -- @param ... Values to return (supports multiple return values)
  -- @return self for chaining
  mock_return_value = function(self, ...)
    self._default_return_value = {...}
    -- Clear default implementation when setting return value
    -- This allows return values to override implementations (useful for spies)
    self._default_implementation = nil
    return self
  end;

  --- Set a return value for the next call only
  -- @param self Mock instance
  -- @param ... Values to return (supports multiple return values)
  -- @return self for chaining
  mock_return_value_once = function(self, ...)
    table.insert(self._return_value_queue, {...})
    -- Note: We don't clear default_implementation here because
    -- the queue takes priority anyway, and we want to preserve
    -- the implementation for subsequent calls
    return self
  end;

  --- Set a default implementation function for all calls
  -- @param self Mock instance
  -- @param func Function to call when mock is invoked
  -- @return self for chaining
  mock_implementation = function(self, func)
    if type(func) ~= 'function' then
      error('mock_implementation expects a function, got ' .. type(func), 2)
    end
    self._default_implementation = func
    return self
  end;

  --- Set an implementation function for the next call only
  -- @param self Mock instance
  -- @param func Function to call when mock is invoked
  -- @return self for chaining
  mock_implementation_once = function(self, func)
    if type(func) ~= 'function' then
      error('mock_implementation_once expects a function, got ' .. type(func), 2)
    end
    table.insert(self._implementation_queue, func)
    return self
  end;

  --- Clear call history but keep implementation and return values
  -- @param self Mock instance
  -- @return self for chaining
  mock_clear = function(self)
    self._call_history = {}
    self._call_count = 0
    return self
  end;

  --- Reset mock to initial state (clears everything)
  -- @param self Mock instance
  -- @return self for chaining
  mock_reset = function(self)
    self._call_history = {}
    self._call_count = 0
    self._default_implementation = nil
    self._default_return_value = nil
    self._implementation_queue = {}
    self._return_value_queue = {}
    return self
  end;

  --- Set a name for the mock (for better error messages)
  -- @param self Mock instance
  -- @param name String name for the mock
  -- @return self for chaining
  mock_name = function(self, name)
    self._name = name
    return self
  end;

  --- Set a sequence of return values (one per call)
  -- @param self Mock instance
  -- @param values Table of values to return in sequence
  -- @return self for chaining
  mock_return_value_sequence = function(self, values)
    for _, value in ipairs(values) do
      table.insert(self._return_value_queue, type(value) == 'table' and value or {value})
    end
    return self
  end;

  --- Clear old call history, keeping only the last n calls
  -- @param self Mock instance
  -- @param keep_last_n Number of recent calls to keep
  -- @return self for chaining
  mock_clear_old_calls = function(self, keep_last_n)
    local history_len = #self._call_history
    if history_len > keep_last_n then
      local new_history = {}
      for i = history_len - keep_last_n + 1, history_len do
        table.insert(new_history, self._call_history[i])
      end
      self._call_history = new_history
      self._call_count = keep_last_n
    end
    return self
  end;

  --- Get the number of times the mock has been called
  -- @param self Mock instance
  -- @return number of calls
  get_call_count = function(self)
    return self._call_count
  end;

  --- Get all calls made to the mock
  -- @param self Mock instance
  -- @return array of call records {args = {...}, return_value = ...}
  get_calls = function(self)
    return self._call_history
  end;

  --- Get a specific call by index (1-indexed)
  -- @param self Mock instance
  -- @param n Call number (1-indexed)
  -- @return call record {args = {...}, return_value = ...} or nil
  get_call = function(self, n)
    return self._call_history[n]
  end;

  --- Get the last call made to the mock
  -- @param self Mock instance
  -- @return call record {args = {...}, return_value = ...} or nil
  get_last_call = function(self)
    return self._call_history[#self._call_history]
  end;

  --- Called when the mock is invoked.
  -- Records the call and returns appropriate value based on configuration.
  -- @param self Mock instance
  -- @param ... Arguments passed to the mock
  __call = function(self, ...)
    local args = {...}
    self._call_count = self._call_count + 1
    
    local return_value = nil
    local return_values = nil
    
    -- Priority order:
    -- 1. Implementation queue (highest priority)
    if #self._implementation_queue > 0 then
      local impl = table.remove(self._implementation_queue, 1)
      return_values = {impl(...)}
      return_value = return_values[1]
    -- 2. Return value queue
    elseif #self._return_value_queue > 0 then
      return_values = table.remove(self._return_value_queue, 1)
      return_value = return_values[1]
    -- 3. Default implementation
    elseif self._default_implementation then
      return_values = {self._default_implementation(...)}
      return_value = return_values[1]
    -- 4. Default return value
    elseif self._default_return_value then
      return_values = self._default_return_value
      return_value = return_values[1]
    -- 5. Return nil (default)
    else
      return_values = {nil}
      return_value = nil
    end
    
    -- Record the call
    table.insert(self._call_history, {
      args = args,
      return_value = return_value,
      return_values = return_values,
    })
    
    -- Return the value(s)
    return table.unpack(return_values)
  end;
}

--- Creates a spy on an existing object method
-- @param object The object to spy on
-- @param method_name The name of the method to spy on
-- @return A Mock instance that wraps the original method
local function spy_on(object, method_name)
  local original = object[method_name]
  if not original then
    error('spy_on: method "' .. tostring(method_name) .. '" does not exist on object', 2)
  end
  if type(original) ~= 'function' then
    error('spy_on: "' .. tostring(method_name) .. '" is not a function', 2)
  end
  
  local spy = Mock()
  spy._original = original
  spy._object = object
  spy._method_name = method_name
  
  -- Override the original method to call the spy
  object[method_name] = function(...)
    return spy(...)
  end
  
  -- Add restore method
  spy.mock_restore = function(self)
    if self._original then
      self._object[self._method_name] = self._original
      self._original = nil
    end
    return self
  end

  -- Set default implementation to call original
  spy:mock_implementation(function(...)
    return original(...)
  end)
  
  return spy
end

return {
  Mock = Mock,
  spy_on = spy_on,
}

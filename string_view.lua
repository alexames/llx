-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class_module = require 'llx.class'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class

--- StringView: A lightweight non-copying view into a substring
StringView = class 'StringView' {
  --- Constructor
  -- @param str: the full source string
  -- @param start: starting index in str (1-based)
  -- @param len: length of the view
  __init = function(self, str, start, len)
    assert(type(str) == "string", "StringView must wrap a string")
    self._str = str
    self._start = start or 1
    self._len = len or (#str - self._start + 1)
  end,

  --- Convert to string (slice view from original)
  __tostring = function(self)
    return self._str:sub(self._start, self._start + self._len - 1)
  end,

  --- Get view length
  length = function(self)
    return self._len
  end,

  --- Access byte by index (relative to the view, 1-based)
  __index = function(self, key)
    -- Methods
    if StringView[key] then return StringView[key] end

    -- Allow byte access via view[1], view[2], ...
    if type(key) == "number" then
      local i = self._start + key - 1
      if i >= self._start and i < self._start + self._len then
        return self._str:byte(i)
      end
      return nil
    end

    -- Special handling for len() - return view length
    if key == "len" then
      return function(_)
        return self._len
      end
    end

    -- Methods that should not be exposed
    local excluded_methods = {
      format = true,
      dump = true,
      pack = true,
      packsize = true,
      unpack = true,
      char = true,
    }
    if excluded_methods[key] then
      return nil
    end

    -- Support for string methods like :sub, :find, :match, etc.
    local str_method = string[key]
    if type(str_method) == "function" then
      return function(_, ...)
        local args = { ... }

        -- Special handling for find() - need to adjust return values to view space
        if key == "find" then
          -- Adjust init parameter if provided
          if #args > 0 and type(args[1]) == "string" then
            local pattern = args[1]
            local init = args[2] or 1
            local plain = args[3]
            -- Convert view-relative init to string-relative
            local str_init = self._start + init - 1
            local str_end = self._start + self._len - 1
            -- Search within view bounds
            local s, e = str_method(self._str, pattern, str_init, plain)
            if s then
              -- Convert back to view-relative positions
              if s >= self._start and s <= str_end then
                return s - self._start + 1, e and (e - self._start + 1) or nil
              end
            end
            return nil
          end
          -- If no init provided, search from start of view
          local s, e = str_method(self._str, args[1], self._start, args[3])
          if s then
            -- Convert back to view-relative positions
            if s >= self._start and s < self._start + self._len then
              return s - self._start + 1, e and (e - self._start + 1) or nil
            end
          end
          return nil
        end

        -- Special handling for reverse() - reverse only the view portion
        if key == "reverse" then
          local view_str = self._str:sub(self._start, self._start + self._len - 1)
          return view_str:reverse()
        end

        -- Adjust start and end indices (if present) for other methods
        for i = 1, math.min(2, #args) do
          if type(args[i]) == "number" then
            args[i] = self._start + args[i] - 1
          end
        end

        local result = str_method(self._str, table.unpack(args))

        -- If result is a string slice, map it back to view space if possible
        if type(result) == "string" and str_method == string.sub then
          return result
        end

        return result
      end
    end
  end,
}

return _M

-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Path manipulation and minimal filesystem helpers.
--
-- A small Path class plus free functions, modeled after Python's
-- pathlib but pared down to what doesn't require external
-- dependencies. Path manipulation is pure string work; the
-- filesystem helpers (exists, read_text, write_text, etc.) use
-- only Lua's stdlib io library.
--
-- Directory listing, mode checks (is_dir vs is_file), file size,
-- and modification time aren't covered here because they require
-- a filesystem library like LuaFileSystem. Install that and use
-- its `lfs` directly when you need them.
--
-- Path syntax is POSIX-style (forward slashes). On Windows, callers
-- should normalize backslashes to forward slashes before
-- constructing a Path, or use `path.normalize` on raw strings.
-- @module llx.path

local class_module = require 'llx.class'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class

-- -------------------------------------------------------------------
-- Free functions: operate on plain strings.
-- -------------------------------------------------------------------

--- Returns true if a path is absolute (starts with '/').
-- @param p Path string
-- @return boolean
function is_absolute(p)
  return p:sub(1, 1) == '/'
end

--- Joins path components with '/'. An absolute component resets
-- the accumulated path to that component (matching Python's
-- os.path.join semantics).
-- @param ... Path components
-- @return Joined path string
-- @usage join('/foo', 'bar', 'baz')  -- '/foo/bar/baz'
function join(...)
  local parts = table.pack(...)
  local result = ''
  for i = 1, parts.n do
    local part = parts[i]
    if type(part) ~= 'string' then
      error('path.join: expected string, got ' .. type(part), 2)
    end
    if is_absolute(part) then
      result = part
    elseif result == '' or result:sub(-1) == '/' then
      result = result .. part
    else
      result = result .. '/' .. part
    end
  end
  return result
end

--- Splits a path into (dirname, basename). The basename is the
-- final component; the dirname is everything before it, without
-- the trailing slash (except for root which keeps '/').
-- @param p Path string
-- @return dirname, basename
function split(p)
  local i = p:find('/[^/]*$')
  if i == nil then return '', p end
  if i == 1 then return '/', p:sub(2) end
  return p:sub(1, i - 1), p:sub(i + 1)
end

--- Returns the parent directory of a path.
-- @param p Path string
-- @return parent
function dirname(p)
  local d, _ = split(p)
  return d == '' and '.' or d
end

--- Returns the final component of a path.
-- @param p Path string
-- @return basename
function basename(p)
  local _, n = split(p)
  return n
end

--- Splits a path into (stem-with-dirs, suffix). Suffix is the
-- text from the last dot in the basename onwards (including the
-- dot). A leading dot (hidden file like '.bashrc') is not treated
-- as a suffix.
-- @param p Path string
-- @return stem_with_dirs, suffix
-- @usage splitext('/a/b.txt')  -- '/a/b', '.txt'
function splitext(p)
  local _, name = split(p)
  -- Find last dot that isn't at position 1 in the basename.
  local dot_in_name = name:find('%.[^.]*$')
  if dot_in_name == nil or dot_in_name == 1 then
    return p, ''
  end
  local cut = #p - #name + dot_in_name
  return p:sub(1, cut - 1), p:sub(cut)
end

--- Collapses '.' and '..' and removes redundant slashes.
-- @param p Path string
-- @return Normalized path
-- @usage normalize('/a/./b/../c')  -- '/a/c'
function normalize(p)
  if p == '' then return '.' end
  local abs = is_absolute(p)
  local parts = {}
  for part in p:gmatch('[^/]+') do
    if part == '..' then
      if #parts > 0 and parts[#parts] ~= '..' then
        table.remove(parts)
      elseif not abs then
        table.insert(parts, '..')
      end
      -- '..' from absolute root stays at root
    elseif part ~= '.' then
      table.insert(parts, part)
    end
  end
  local result = table.concat(parts, '/')
  if abs then result = '/' .. result end
  if result == '' then result = abs and '/' or '.' end
  return result
end

-- -------------------------------------------------------------------
-- Path class: structural wrapper around a path string.
-- -------------------------------------------------------------------

Path = class 'Path' {
  __init = function(self, str)
    if type(str) == 'table' and str._str then
      -- Allow Path(other_path) as identity constructor.
      str = str._str
    end
    if type(str) ~= 'string' then
      error('Path: expected string, got ' .. type(str), 2)
    end
    rawset(self, '_str', str)
  end,

  --- The parent directory as a new Path.
  parent = function(self)
    return Path(dirname(self._str))
  end,

  --- The final path component.
  name = function(self)
    return basename(self._str)
  end,

  --- The final component without its suffix.
  stem = function(self)
    local n = basename(self._str)
    local dot = n:find('%.[^.]*$')
    if dot == nil or dot == 1 then return n end
    return n:sub(1, dot - 1)
  end,

  --- The suffix including the leading dot, or '' if none.
  suffix = function(self)
    local _, s = splitext(self._str)
    return s
  end,

  --- All suffixes, in order. `Path('archive.tar.gz'):suffixes()`
  -- returns {'.tar', '.gz'}.
  suffixes = function(self)
    local n = basename(self._str)
    local list = {}
    -- Skip leading dot for hidden files.
    local start = n:sub(1, 1) == '.' and 2 or 1
    for s in n:sub(start):gmatch('(%.[^.]+)') do
      list[#list + 1] = s
    end
    return list
  end,

  --- Path components as a list. Absolute paths include '/' as
  -- the first element.
  parts = function(self)
    local result = {}
    if is_absolute(self._str) then result[1] = '/' end
    for part in self._str:gmatch('[^/]+') do
      result[#result + 1] = part
    end
    return result
  end,

  --- True if absolute.
  is_absolute = function(self) return is_absolute(self._str) end,

  --- Appends one or more components, returning a new Path.
  join = function(self, ...)
    return Path(join(self._str, ...))
  end,

  --- Returns a new Path with the final component replaced.
  with_name = function(self, new_name)
    local d = dirname(self._str)
    if d == '.' or d == '' then return Path(new_name) end
    return Path(d .. '/' .. new_name)
  end,

  --- Returns a new Path with the suffix replaced. new_suffix
  -- should include the leading dot (e.g. '.lua'). Pass '' to
  -- strip the suffix.
  with_suffix = function(self, new_suffix)
    local stem_with_dirs, _ = splitext(self._str)
    return Path(stem_with_dirs .. new_suffix)
  end,

  --- Returns a normalized copy of this Path.
  normalize = function(self)
    return Path(normalize(self._str))
  end,

  -- ---------------------------------------------------------------
  -- Filesystem helpers (stdlib-only)
  -- ---------------------------------------------------------------

  --- Returns true if the path can be opened for reading.
  -- This is the only filesystem-touching check available without
  -- a library like LuaFileSystem; it can't distinguish files from
  -- directories on all platforms.
  exists = function(self)
    local f = io.open(self._str, 'rb')
    if f then f:close(); return true end
    return false
  end,

  --- Reads the entire file as a string. Raises if the file
  -- doesn't exist or can't be read.
  read_text = function(self)
    local f, err = io.open(self._str, 'r')
    if not f then error('Path.read_text: ' .. (err or 'unknown'), 2) end
    local content = f:read('*a')
    f:close()
    return content
  end,

  --- Reads the entire file in binary mode.
  read_bytes = function(self)
    local f, err = io.open(self._str, 'rb')
    if not f then error('Path.read_bytes: ' .. (err or 'unknown'), 2) end
    local content = f:read('*a')
    f:close()
    return content
  end,

  --- Writes content as text. Truncates the file if it exists.
  -- @return self for chaining
  write_text = function(self, content)
    local f, err = io.open(self._str, 'w')
    if not f then error('Path.write_text: ' .. (err or 'unknown'), 2) end
    f:write(content)
    f:close()
    return self
  end,

  --- Writes content in binary mode. Truncates the file if it exists.
  -- @return self for chaining
  write_bytes = function(self, content)
    local f, err = io.open(self._str, 'wb')
    if not f then error('Path.write_bytes: ' .. (err or 'unknown'), 2) end
    f:write(content)
    f:close()
    return self
  end,

  __tostring = function(self) return self._str end,

  __eq = function(a, b)
    -- Compare normalized forms so equivalent paths compare equal.
    return normalize(a._str) == normalize(b._str)
  end,

  __hash = function(self, result)
    local hash = require 'llx.hash'
    return hash.hash_string(normalize(self._str), result)
  end,

  --- The `/` operator returns a new Path with the right side
  -- appended, matching Python's pathlib syntax:
  --     Path('/foo') / 'bar' / 'baz.txt'
  __div = function(a, b)
    -- Either operand may be a Path or a string.
    local left = type(a) == 'table' and a._str or a
    local right = type(b) == 'table' and b._str or b
    return Path(join(left, right))
  end,
}

return _M

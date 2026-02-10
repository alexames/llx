--- Bytecode utility functions for dumping and comparing compiled Lua code.
-- Provides tools to serialize parsed bytecode prototypes to text files
-- and compare the bytecode output of two functions side by side.
-- @module llx.bytecode.lua54.util

local environment = require 'llx.environment'
local bcode = require 'llx.bytecode.lua54.bcode'

local _ENV, _M = environment.create_module_environment()

--- Write content to a file-like object with indentation.
-- @param file a file object or any object with a write method
-- @param indent the indentation level (each level is two spaces)
-- @param ... additional arguments to write after the indentation
local function write_indented(file, indent, ...)
  for i=1, indent do
    file:write('  ')
  end
  file:write(...)
end

--- Recursively serialize a value to a file-like object.
-- Tables are printed with sorted keys and nested indentation. Values
-- with a __tostring metamethod use tostring(). Strings are quoted.
-- @param file a file object or any object with a write method
-- @param o the value to serialize
-- @param indent the current indentation level (default 0)
function write_recursive(file, o, indent)
  indent = indent or 0
  local mt = getmetatable(o)
  if mt and mt.__tostring then
    file:write(tostring(o))
  elseif type(o) == 'table' then
    file:write('{\n')
    local keys = {}
    for k in pairs(o) do
      table.insert(keys, k)
    end
    table.sort(keys)
    for i, k in ipairs(keys) do
      local v = o[k]
      write_indented(file, indent + 1, k, ' = ')
      write_recursive(file, v, indent + 1)
      file:write(',\n')
    end
    write_indented(file, indent, '}')
  elseif type(o) == 'string' then
    file:write("'", tostring(o), "'")
  else
    file:write(tostring(o))
  end
end

--- Dump a compiled chunk to a text file.
-- Parses the bytecode and writes a human-readable representation
-- to a file named <filename>.txt.
-- @param filename the base filename (without extension)
-- @param chunk a binary string from string.dump
function dump_file(filename, chunk)
  local chunk_bytes = bcode.read_bytes(chunk)
  do
    local file <close> = assert(io.open(filename .. '.txt', 'w'))
    write_recursive(file, chunk_bytes)
  end
end

--- Compare the bytecode of two functions by dumping each to a text file.
-- Writes 'left.txt' and 'right.txt' for manual diff comparison.
-- @param f1 the first function to compare
-- @param f2 the second function to compare
function compare_two_functions(f1, f2)
  dump_file('left', string.dump(f1))
  dump_file('right', string.dump(f2))
end

return _M

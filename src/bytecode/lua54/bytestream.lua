--- Byte stream reader for parsing binary data.
-- Provides sequential reading of bytes, integers, floats, varints,
-- strings, and aligned data from a binary string. Used as the
-- low-level reader for Lua 5.4 bytecode files.
-- @module llx.bytecode.lua54.bytestream

local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local bytestream_metatable = {
  --- Read a 32-bit little-endian integer from the stream.
  -- @return the decoded 32-bit integer value
  read_int32 = function(self)
    return self:read_int8() << 0
           | self:read_int8() << 8
           | self:read_int8() << 16
           | self:read_int8() << 24
  end,

  --- Read a single byte from the stream.
  -- Advances the stream position by one byte. Optionally logs the byte
  -- value if logging is enabled.
  -- @return the byte value as an integer (0-255)
  read_int8 = function(self)
    self._index = self._index + 1
    local byte = self._bytes:sub(self._index, self._index):byte()
    if self._log_bytes then
      print(string.format('%i: 0x%02X | %i', self._index, byte, byte))
    end
    return byte
  end,

  --- Read a vector of n elements, transforming each byte and combining results.
  -- @param n the number of bytes to read
  -- @param vector_fn function to combine the element results into a final value
  -- @param element_fn function to transform each individual byte
  -- @return the result of vector_fn applied to the transformed elements
  read_vector = function(self, n, vector_fn, element_fn)
    local result = {}
    for i=1, n do
      table.insert(result, element_fn(self:read_int8()))
    end
    return vector_fn(result)
  end,

  --- Read n bytes as a string by converting each byte to its character.
  -- @param n the number of bytes to read
  -- @return the resulting string
  read_string_vector = function(self, n)
    return self:read_vector(n, table.concat, string.char)
  end,

  --- Read n bytes as a raw byte vector (no transformation).
  -- @param n the number of bytes to read
  -- @return a table of byte values
  read_byte_vector = function(self, n)
    local function noop(...) return ... end
    return self:read_vector(n, noop, noop)
  end,

  --- Read n bytes as a literal string.
  -- Similar to read_string_vector but builds the string character by character.
  -- @param n the number of bytes to read
  -- @return the resulting string
  read_literal = function(self, n)
    local s = {}
    for i=1, n do
      local byte = self:read_int8()
      table.insert(s, string.char(byte))
    end
    return table.concat(s)
  end,

  --- Advance the stream position to the next alignment boundary.
  -- @param align the alignment boundary in bytes
  read_align = function(self, align)
    local i = self._index - 1
    self._index = i + align - (i % align)
  end,

  --- Read an 8-byte IEEE 754 double-precision floating point number.
  -- @return the decoded number value
  read_number = function(self)
    local bytes = {}
    for i=1, 8 do
      bytes[i] = string.char(self:read_int8())
    end
    return string.unpack('n', table.concat(bytes))
  end,

  --- Read an 8-byte signed integer.
  -- @return the decoded integer value
  read_integer = function(self)
    local bytes = {}
    for i=1, 8 do
      bytes[i] = string.char(self:read_int8())
    end
    return string.unpack('j', table.concat(bytes))
  end,

  --- Read a variable-length integer (varint).
  -- Each byte contributes 7 bits of data. The high bit indicates whether
  -- this is the last byte (1 = last byte, 0 = more bytes follow).
  -- @return the decoded integer value
  read_varint = function(self)
    local result = 0
    repeat
      local value = self:read_int8()
      result = (result << 7) | (value & 0x7f)
    until value & 0x80 ~= 0
    return result
  end,

  --- Read a size value (alias for read_varint).
  -- @return the decoded size value
  read_size = function(self)
    return self:read_varint()
  end,
}
bytestream_metatable.__index = bytestream_metatable

--- Create a new ByteStream from a binary string.
-- @param bytes the binary string to read from
-- @param log_bytes if truthy, print each byte as it is read
-- @return a new ByteStream object
function ByteStream(bytes, log_bytes)
  return setmetatable({_bytes=bytes, _index=0, _log_bytes=log_bytes},
                      bytestream_metatable)
end

return _M

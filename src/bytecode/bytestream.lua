
bytestream_metatable = {
  read_int32 = function(self)
    return self:read_int8() << 0
           | self:read_int8() << 8
           | self:read_int8() << 16
           | self:read_int8() << 24
  end,

  read_int8 = function(self)
    self._index = self._index + 1
    local byte = self._bytes:sub(self._index, self._index):byte()
    if self._log_bytes then
      print(string.format('%i: 0x%02X | %i', self._index, byte, byte))
    end
    return byte
  end,

  read_vector = function(self, n, vector_fn, element_fn)
    local result = {}
    for i=1, n do
      table.insert(result, element_fn(self:read_int8()))
    end
    return vector_fn(result)
  end,

  read_string_vector = function(self, n)
    return self:read_vector(n, table.concat, string.char)
  end,

  read_byte_vector = function(self, n)
    local function noop(...) return ... end
    return self:read_vector(n, noop, noop)
  end,

  read_literal = function(self, n)
    local s = {}
    for i=1, n do
      local byte = self:read_int8()
      table.insert(s, string.char(byte))
    end
    return table.concat(s)
  end,

  read_align = function(self, align)
    local i = self._index - 1
    self._index = i + align - (i % align)
  end,

  read_number = function(self)
    local bytes = {}
    for i=1, 8 do
      bytes[i] = string.char(self:read_int8())
    end
    return string.unpack('n', table.concat(bytes))
  end,

  read_integer = function(self)
    local bytes = {}
    for i=1, 8 do
      bytes[i] = string.char(self:read_int8())
    end
    return string.unpack('j', table.concat(bytes))
  end,

  read_varint = function(self)
    local result = 0
    repeat
      local value = self:read_int8()
      result = (result << 7) | (value & 0x7f)
    until value & 0x80 == 0
    return result
  end,

  read_size = function(self)
    return self:read_varint()
  end,
}
bytestream_metatable.__index = bytestream_metatable

function ByteStream(bytes, log_bytes)
  return setmetatable({_bytes=bytes, _index=0, _log_bytes=log_bytes},
                      bytestream_metatable)
end

return {
  ByteStream=ByteStream
}

local unit = require 'llx.unit'
local llx = require 'llx'

local bytestream_module = require 'llx.bytecode.lua54.bytestream'
local ByteStream = bytestream_module.ByteStream

_ENV = unit.create_test_env(_ENV)

describe('bytestream', function()
  describe('read_int8', function()
    it('should read a single byte', function()
      local stream = ByteStream(string.char(0x41))
      expect(stream:read_int8()).to.be_equal_to(0x41)
    end)

    it('should read bytes sequentially', function()
      local stream = ByteStream(string.char(0x01, 0x02, 0x03))
      expect(stream:read_int8()).to.be_equal_to(0x01)
      expect(stream:read_int8()).to.be_equal_to(0x02)
      expect(stream:read_int8()).to.be_equal_to(0x03)
    end)

    it('should read zero byte', function()
      local stream = ByteStream(string.char(0x00))
      expect(stream:read_int8()).to.be_equal_to(0)
    end)

    it('should read max byte value 255', function()
      local stream = ByteStream(string.char(0xFF))
      expect(stream:read_int8()).to.be_equal_to(255)
    end)
  end)

  describe('read_int32', function()
    it('should read little-endian value of 1', function()
      local stream = ByteStream(string.char(0x01, 0x00, 0x00, 0x00))
      expect(stream:read_int32()).to.be_equal_to(1)
    end)

    it('should read little-endian value of 0x5678', function()
      local stream = ByteStream(string.char(0x78, 0x56, 0x00, 0x00))
      expect(stream:read_int32()).to.be_equal_to(0x5678)
    end)

    it('should read zero', function()
      local stream = ByteStream(string.char(0x00, 0x00, 0x00, 0x00))
      expect(stream:read_int32()).to.be_equal_to(0)
    end)

    it('should read value with all bytes set', function()
      local stream = ByteStream(string.char(0xFF, 0xFF, 0xFF, 0xFF))
      expect(stream:read_int32()).to.be_equal_to(0xFFFFFFFF)
    end)

    it('should read little-endian value 0x04030201', function()
      local stream = ByteStream(string.char(0x01, 0x02, 0x03, 0x04))
      expect(stream:read_int32()).to.be_equal_to(0x04030201)
    end)

    it('should read two consecutive int32 values', function()
      local stream = ByteStream(string.char(
        0x01, 0x00, 0x00, 0x00,
        0x02, 0x00, 0x00, 0x00
      ))
      expect(stream:read_int32()).to.be_equal_to(1)
      expect(stream:read_int32()).to.be_equal_to(2)
    end)
  end)

  describe('read_literal', function()
    it('should read an exact string', function()
      local stream = ByteStream('\x1bLua')
      expect(stream:read_literal(4)).to.be_equal_to('\x1bLua')
    end)

    it('should read a single character', function()
      local stream = ByteStream('A')
      expect(stream:read_literal(1)).to.be_equal_to('A')
    end)

    it('should read an empty string when n is 0', function()
      local stream = ByteStream('hello')
      expect(stream:read_literal(0)).to.be_equal_to('')
    end)

    it('should read consecutive literals', function()
      local stream = ByteStream('helloworld')
      expect(stream:read_literal(5)).to.be_equal_to('hello')
      expect(stream:read_literal(5)).to.be_equal_to('world')
    end)
  end)

  describe('read_string_vector', function()
    it('should read bytes as a string like read_literal', function()
      local stream = ByteStream('ABCD')
      expect(stream:read_string_vector(4)).to.be_equal_to('ABCD')
    end)

    it('should read a single character', function()
      local stream = ByteStream('X')
      expect(stream:read_string_vector(1)).to.be_equal_to('X')
    end)

    it('should read binary data as a string', function()
      local stream = ByteStream(string.char(0x48, 0x69))
      expect(stream:read_string_vector(2)).to.be_equal_to('Hi')
    end)

    it('should produce same result as read_literal for same input', function()
      local data = 'test data'
      local stream1 = ByteStream(data)
      local stream2 = ByteStream(data)
      expect(stream1:read_literal(9))
        .to.be_equal_to(stream2:read_string_vector(9))
    end)
  end)

  describe('read_varint', function()
    it('should read single-byte value of 0', function()
      -- Single byte: 0x80 (high bit set = last byte, value bits = 0)
      local stream = ByteStream(string.char(0x80))
      expect(stream:read_varint()).to.be_equal_to(0)
    end)

    it('should read single-byte value of 1', function()
      -- Single byte: 0x81 (high bit set = last byte, value bits = 1)
      local stream = ByteStream(string.char(0x81))
      expect(stream:read_varint()).to.be_equal_to(1)
    end)

    it('should read single-byte value of 127', function()
      -- Single byte: 0xFF (high bit set = last byte, value bits = 127)
      local stream = ByteStream(string.char(0xFF))
      expect(stream:read_varint()).to.be_equal_to(127)
    end)

    it('should read multi-byte varint for value 128', function()
      -- 128 = 1 * 128 + 0
      -- First byte: 0x01 (high bit clear = more bytes, value bits = 1)
      -- Second byte: 0x80 (high bit set = last byte, value bits = 0)
      -- Result: (1 << 7) | 0 = 128
      local stream = ByteStream(string.char(0x01, 0x80))
      expect(stream:read_varint()).to.be_equal_to(128)
    end)

    it('should read multi-byte varint for value 255', function()
      -- 255 = 1 * 128 + 127
      -- First byte: 0x01 (high bit clear = more bytes, value bits = 1)
      -- Second byte: 0xFF (high bit set = last byte, value bits = 127)
      -- Result: (1 << 7) | 127 = 255
      local stream = ByteStream(string.char(0x01, 0xFF))
      expect(stream:read_varint()).to.be_equal_to(255)
    end)

    it('should read multi-byte varint for value 300', function()
      -- 300 = 2 * 128 + 44
      -- First byte: 0x02 (high bit clear = more bytes, value bits = 2)
      -- Second byte: 0x80 | 0x2C = 0xAC
      -- (high bit set = last byte, value bits = 44)
      -- Result: (2 << 7) | 44 = 256 + 44 = 300
      local stream = ByteStream(string.char(0x02, 0xAC))
      expect(stream:read_varint()).to.be_equal_to(300)
    end)

    it('should read_size as alias for read_varint', function()
      local stream1 = ByteStream(string.char(0x02, 0xAC))
      local stream2 = ByteStream(string.char(0x02, 0xAC))
      expect(stream1:read_size()).to.be_equal_to(stream2:read_varint())
    end)
  end)

  describe('read_number', function()
    it('should read IEEE 754 double 370.5', function()
      local packed = string.pack('n', 370.5)
      local stream = ByteStream(packed)
      expect(stream:read_number()).to.be_equal_to(370.5)
    end)

    it('should read IEEE 754 double 0.0', function()
      local packed = string.pack('n', 0.0)
      local stream = ByteStream(packed)
      expect(stream:read_number()).to.be_equal_to(0.0)
    end)

    it('should read IEEE 754 double 1.0', function()
      local packed = string.pack('n', 1.0)
      local stream = ByteStream(packed)
      expect(stream:read_number()).to.be_equal_to(1.0)
    end)

    it('should read negative double', function()
      local packed = string.pack('n', -42.25)
      local stream = ByteStream(packed)
      expect(stream:read_number()).to.be_equal_to(-42.25)
    end)

    it('should read very small double', function()
      local packed = string.pack('n', 0.001)
      local stream = ByteStream(packed)
      expect(stream:read_number()).to.be_equal_to(0.001)
    end)
  end)

  describe('read_integer', function()
    it('should read 8-byte integer 0x5678', function()
      local packed = string.pack('j', 0x5678)
      local stream = ByteStream(packed)
      expect(stream:read_integer()).to.be_equal_to(0x5678)
    end)

    it('should read 8-byte integer 0', function()
      local packed = string.pack('j', 0)
      local stream = ByteStream(packed)
      expect(stream:read_integer()).to.be_equal_to(0)
    end)

    it('should read 8-byte integer 1', function()
      local packed = string.pack('j', 1)
      local stream = ByteStream(packed)
      expect(stream:read_integer()).to.be_equal_to(1)
    end)

    it('should read negative 8-byte integer', function()
      local packed = string.pack('j', -1)
      local stream = ByteStream(packed)
      expect(stream:read_integer()).to.be_equal_to(-1)
    end)

    it('should read large positive integer', function()
      local packed = string.pack('j', 1000000)
      local stream = ByteStream(packed)
      expect(stream:read_integer()).to.be_equal_to(1000000)
    end)
  end)

  describe('read_byte_vector', function()
    it('should return a table of raw byte values', function()
      local stream = ByteStream(string.char(0x01, 0x02, 0x03))
      local result = stream:read_byte_vector(3)
      expect(result[1]).to.be_equal_to(0x01)
      expect(result[2]).to.be_equal_to(0x02)
      expect(result[3]).to.be_equal_to(0x03)
    end)

    it('should return a table with one element for single byte', function()
      local stream = ByteStream(string.char(0xFF))
      local result = stream:read_byte_vector(1)
      expect(result[1]).to.be_equal_to(0xFF)
    end)

    it('should return a table of zeros', function()
      local stream = ByteStream(string.char(0x00, 0x00, 0x00))
      local result = stream:read_byte_vector(3)
      expect(result[1]).to.be_equal_to(0)
      expect(result[2]).to.be_equal_to(0)
      expect(result[3]).to.be_equal_to(0)
    end)

    it('should advance stream position', function()
      local stream = ByteStream(string.char(0x01, 0x02, 0x03, 0x04))
      stream:read_byte_vector(2)
      expect(stream:read_int8()).to.be_equal_to(0x03)
    end)
  end)

  describe('read_align', function()
    it('should advance position to alignment boundary', function()
      -- Start at index 0, read 1 byte to move to index 1,
      -- then align to 4 should skip to index 4 (next 4-byte boundary)
      local stream = ByteStream(string.char(
        0xAA, 0x00, 0x00, 0x00,
        0xBB, 0x00, 0x00, 0x00
      ))
      stream:read_int8()       -- index is now 1
      stream:read_align(4)     -- should advance to index 4
      expect(stream:read_int8()).to.be_equal_to(0xBB)
    end)

    it('should not skip when already aligned', function()
      -- Read 4 bytes to land on index 4, align to 4 should stay at 4
      local stream = ByteStream(string.char(
        0x01, 0x02, 0x03, 0x04,
        0x05, 0x06, 0x07, 0x08
      ))
      stream:read_int8()  -- index 1
      stream:read_int8()  -- index 2
      stream:read_int8()  -- index 3
      stream:read_int8()  -- index 4
      stream:read_align(4)  -- index 4 is already aligned on 4-byte boundary
      expect(stream:read_int8()).to.be_equal_to(0x05)
    end)

    it('should align to 2-byte boundary', function()
      local stream = ByteStream(string.char(0xAA, 0xBB, 0xCC))
      stream:read_int8()       -- index is now 1
      stream:read_align(2)     -- should advance to index 2
      expect(stream:read_int8()).to.be_equal_to(0xCC)
    end)
  end)

  describe('mixed reads', function()
    it('should correctly sequence different read operations', function()
      local number_bytes = string.pack('n', 3.14)
      local data = string.char(0x01, 0x02, 0x00, 0x00) .. 'Hi' .. number_bytes
      local stream = ByteStream(data)

      expect(stream:read_int32()).to.be_equal_to(0x0201)
      expect(stream:read_literal(2)).to.be_equal_to('Hi')
      expect(stream:read_number()).to.be_equal_to(3.14)
    end)
  end)

  describe('log_bytes', function()
    it('should accept log_bytes parameter without error', function()
      local stream = ByteStream(string.char(0x01), false)
      expect(stream:read_int8()).to.be_equal_to(0x01)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

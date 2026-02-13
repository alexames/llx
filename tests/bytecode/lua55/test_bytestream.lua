local unit = require 'llx.unit'
local llx = require 'llx'

local bytestream_module = require 'llx.bytecode.lua55.bytestream'
local ByteStream = bytestream_module.ByteStream

_ENV = unit.create_test_env(_ENV)

describe('bytestream (lua55)', function()
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
  end)

  describe('read_varint (lua 5.5 convention)', function()
    -- Lua 5.5 varint: high bit 1 = more bytes, high bit 0 = last byte
    -- (opposite of Lua 5.4)

    it('should read single-byte value of 0', function()
      -- Single byte: 0x00 (high bit clear = last byte, value bits = 0)
      local stream = ByteStream(string.char(0x00))
      expect(stream:read_varint()).to.be_equal_to(0)
    end)

    it('should read single-byte value of 1', function()
      -- Single byte: 0x01 (high bit clear = last byte, value bits = 1)
      local stream = ByteStream(string.char(0x01))
      expect(stream:read_varint()).to.be_equal_to(1)
    end)

    it('should read single-byte value of 127', function()
      -- Single byte: 0x7F (high bit clear = last byte, value bits = 127)
      local stream = ByteStream(string.char(0x7F))
      expect(stream:read_varint()).to.be_equal_to(127)
    end)

    it('should read multi-byte varint for value 128', function()
      -- 128 = 1 * 128 + 0
      -- First byte: 0x81 (high bit set = more bytes, value bits = 1)
      -- Second byte: 0x00 (high bit clear = last byte, value bits = 0)
      -- Result: (1 << 7) | 0 = 128
      local stream = ByteStream(string.char(0x81, 0x00))
      expect(stream:read_varint()).to.be_equal_to(128)
    end)

    it('should read multi-byte varint for value 255', function()
      -- 255 = 1 * 128 + 127
      -- First byte: 0x81 (high bit set = more bytes, value bits = 1)
      -- Second byte: 0x7F (high bit clear = last byte, value bits = 127)
      -- Result: (1 << 7) | 127 = 255
      local stream = ByteStream(string.char(0x81, 0x7F))
      expect(stream:read_varint()).to.be_equal_to(255)
    end)

    it('should read multi-byte varint for value 300', function()
      -- 300 = 2 * 128 + 44
      -- First byte: 0x82 (high bit set = more bytes, value bits = 2)
      -- Second byte: 0x2C (high bit clear = last byte, value bits = 44)
      -- Result: (2 << 7) | 44 = 256 + 44 = 300
      local stream = ByteStream(string.char(0x82, 0x2C))
      expect(stream:read_varint()).to.be_equal_to(300)
    end)

    it('should read_size as alias for read_varint', function()
      local stream1 = ByteStream(string.char(0x82, 0x2C))
      local stream2 = ByteStream(string.char(0x82, 0x2C))
      expect(stream1:read_size()).to.be_equal_to(stream2:read_varint())
    end)
  end)

  describe('read_number', function()
    it('should read IEEE 754 double 370.5', function()
      local packed = string.pack('n', 370.5)
      local stream = ByteStream(packed)
      expect(stream:read_number()).to.be_equal_to(370.5)
    end)

    it('should read negative double', function()
      local packed = string.pack('n', -370.5)
      local stream = ByteStream(packed)
      expect(stream:read_number()).to.be_equal_to(-370.5)
    end)
  end)

  describe('read_integer', function()
    it('should read 8-byte integer 0x5678', function()
      local packed = string.pack('j', 0x5678)
      local stream = ByteStream(packed)
      expect(stream:read_integer()).to.be_equal_to(0x5678)
    end)

    it('should read negative 8-byte integer', function()
      local packed = string.pack('j', -0x5678)
      local stream = ByteStream(packed)
      expect(stream:read_integer()).to.be_equal_to(-0x5678)
    end)
  end)

  describe('read_align', function()
    it('should advance position to alignment boundary', function()
      local stream = ByteStream(string.char(
        0xAA, 0x00, 0x00, 0x00,
        0xBB, 0x00, 0x00, 0x00
      ))
      stream:read_int8()       -- index is now 1
      stream:read_align(4)     -- should advance to index 4
      expect(stream:read_int8()).to.be_equal_to(0xBB)
    end)

    it('should not skip when already aligned', function()
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
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

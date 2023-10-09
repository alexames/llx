local function writeUInt32be(file, i)
  file:write(
    string.char(
      bit32.rshift(i, 24) % 256,
      bit32.rshift(i, 16) % 256,
      bit32.rshift(i, 8) % 256,
      bit32.rshift(i, 0) % 256))
end

local function writeUInt16be(file, i)
  file:write(
    string.char(
      bit32.rshift(i, 8) % 256,
      bit32.rshift(i, 0) % 256))
end

local function writeUInt8be(file, i)
  file:write(
    string.char(
      bit32.rshift(i, 0) % 256))
end
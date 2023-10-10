local function writeUInt32be(file, i)
  file:write(
    string.char(
      (i >> 24) & 0xFF,
      (i >> 16) & 0xFF,
      (i >> 8) & 0xFF,
      (i >> 0) & 0xFF))
end

local function writeUInt16be(file, i)
  file:write(
    string.char(
      (i >> 8) & 0xFF,
      (i >> 0) & 0xFF))
end

local function writeUInt8be(file, i)
  file:write(
    string.char(
      (i >> 0) & 0xFF))
end

return {
  writeUInt32be=writeUInt32be,
  writeUInt16be=writeUInt16be,
  writeUInt8be=writeUInt8be,
}
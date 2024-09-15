local bytestream = require 'bytestream'
local constants = require 'constants'
local instructions = require 'instructions'
local opcodes = require 'opcodes'
local typetags_module = require 'typetags'

local typetags = typetags_module.typetags

local LUA_SIGNATURE = '\x1bLua'
local LUAC_DATA = '\x19\x93\r\n\x1a\n'
local LUAC_INT = 0x5678
local LUAC_NUM = 370.5

local PF_ISVARARG = 1

function load_code(proto, meta, bytestream)
  local sizecode = bytestream:read_varint()
  bytestream:read_align(meta.instruction_size)
  proto.code = {}
  for i=1, sizecode do
    proto.code[i] = Instruction(bytestream:read_int32(), proto)
  end
end

function load_constants(proto, meta, bytestream)
  local k = {}
  proto.k = k
  for i=1, bytestream:read_varint() do
    local typetag = bytestream:read_int8()
    if typetag == typetags.vnumflt.value then
      k[i] = bytestream:read_number()
    elseif typetag == typetags.vnumint.value then
      k[i] = bytestream:read_integer()
    elseif typetag == typetags.vsrtstr.value
           or typetag == typetags.vlngstr.value then
      k[i] = load_string(proto, meta, bytestream)
    else
      assert(typetags[typetag] == typetags.tnil
             or typetags[typetag] == typetags.vtrue
             or typetags[typetag] == typetags.vfalse,
             string.format('typetag was %s (0x%X)', typetags[typetag], typetag))
    end
  end
end

function load_upvalues(proto, meta, bytestream)
  local upvalues = {}
  proto.upvalues = upvalues
  for i=1, bytestream:read_varint() do
    upvalues[i] = {
      instack = bytestream:read_int8(),
      idx = bytestream:read_int8(),
      kind = bytestream:read_int8(),
    }
  end
end

function load_protos(proto, meta, bytestream)
  proto.p = {}
  for i=1, bytestream:read_varint() do
    local p = {}
    proto.p[i] = p
    load_function(p, meta, bytestream)
  end
end

function load_string(proto, meta, bytestream)
  local size = bytestream:read_size()
  if size == 0 then
    assert(false, 'unimplemented a')
  elseif size == 1 then
    local index = bytestream:read_varint()
    return meta.strings[index]
  else
    local adjusted_size = size - 2
    local s = bytestream:read_string_vector(adjusted_size, true)
    bytestream:read_int8() -- bypass the null character.
    table.insert(meta.strings, s)
    return s
  end
end

function read_debug(proto, meta, bytestream)
  proto.sizelineinfo = bytestream:read_varint()
  proto.lineinfo = bytestream:read_byte_vector(proto.sizelineinfo)
  proto.sizeabslineinfo = bytestream:read_varint()
  if proto.sizeabslineinfo > 0 then
    -- 'abslineinfo' is an array of structures of int's
    bytestream:read_align(meta.integer_size)
    proto.abslineinfo = bytestream:read_byte_vector(
      proto.sizelineinfo * meta.integer_size)
  end
  proto.locvars = {}
  for i=1, bytestream:read_varint() do
    proto.locvars[i] = {
      varname = load_string(proto, meta, bytestream),
      startpc = bytestream:read_varint(),
      endpc = bytestream:read_varint(),
    }
  end
  proto.upvalues = {}
  for i=1, bytestream:read_varint() do
    proto.upvalues[i] = {
      name = load_string(proto, meta, bytestream)
    }
  end
end

function load_header(proto, meta, bytestream)
  local signature = bytestream:read_literal(#LUA_SIGNATURE)
  assert(signature == LUA_SIGNATURE, 'not a binary chunk')
  local version = bytestream:read_int8()
  meta.version = {
    major = version & 0xF0 >> 4,
    minor = version & 0x0F,
  }
  proto.format = bytestream:read_int8()
  assert(bytestream:read_literal(#LUAC_DATA) == LUAC_DATA, 'corrupted chunk')
  meta.instruction_size = bytestream:read_int8()
  meta.integer_size = bytestream:read_int8()
  meta.number_size = bytestream:read_int8()
  assert(bytestream:read_integer() == LUAC_INT, 'integer format mismatch')
  assert(bytestream:read_number() == LUAC_NUM, 'float format mismatch')
end

function load_function(proto, meta, bytestream)
  proto.linedefined = bytestream:read_varint()
  proto.lastlinedefined = bytestream:read_varint()
  proto.numparams = bytestream:read_int8()
  proto.flag = bytestream:read_int8() & PF_ISVARARG -- get only the meaningful flags
  proto.maxstacksize = bytestream:read_int8()
  load_code(proto, meta, bytestream)
  load_constants(proto, meta, bytestream)
  load_upvalues(proto, meta, bytestream)
  load_protos(proto, meta, bytestream)
  proto.source = load_string(proto, meta, bytestream)
  read_debug(proto, meta, bytestream)
end

function read_bytes(bytes)
  local proto = {}
  local meta = {strings={}}
  local bytestream = bytestream.ByteStream(bytes)
  load_header(proto, meta, bytestream)
  local sizeupvalues = bytestream:read_int8()
  load_function(proto, meta, bytestream)
  return proto, meta
end

function to_bytestream(filename)
  do
    local file <close> = assert(io.open(filename, 'rb'))
    local bytestream = bytestream.ByteStream(assert(file:read(4)))

    -- Starting with the Lua signature escape code indicates this is a Lua
    -- bytecode file, so read the whole file into memory so it can be processed.
    local signature = bytestream:read_literal(#LUA_SIGNATURE)
    if signature == LUA_SIGNATURE then
      file:seek('set', 0)
      local contents = assert(file:read('a'))
      return bytestream.ByteStream(contents)
    end
  end
  -- This is a Lua source code file, so load and compile the file and dump the
  -- raw bytes so that it can be processed.
  local chunk = assert(loadfile(filename))
  return bytestream.ByteStream(string.dump(chunk))
end

function read_file(filename)
  local bytestream = to_bytestream(filename)
  return read_bytes(bytestream)
end

return {
  read_bytes = read_bytes,
  read_file = read_file,
}

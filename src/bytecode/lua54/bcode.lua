--- Lua 5.4 bytecode file reader.
-- Parses compiled Lua 5.4 binary chunks into structured prototype tables
-- containing code, constants, upvalues, nested prototypes, and debug info.
-- Can read both pre-compiled bytecode files and Lua source files (by
-- compiling them first via loadfile/string.dump).
-- @module llx.bytecode.lua54.bcode

local environment = require 'llx.environment'
local bytestream_module = require 'llx.bytecode.lua54.bytestream'
local instructions_module = require 'llx.bytecode.lua54.instructions'
local typetags_module = require 'llx.bytecode.lua54.typetags'

local _ENV, _M = environment.create_module_environment()

local ByteStream = bytestream_module.ByteStream
local Instruction = instructions_module.Instruction
local typetags = typetags_module.typetags

local LUA_SIGNATURE = '\x1bLua'
local LUAC_DATA = '\x19\x93\r\n\x1a\n'
local LUAC_INT = 0x5678
local LUAC_NUM = 370.5

local PF_ISVARARG = 1

--- Load the code (instruction) section of a function prototype.
-- Reads the instruction count and then each 32-bit instruction word.
-- @param proto the prototype table to populate
-- @param meta metadata table containing instruction_size
-- @param stream the ByteStream to read from
local function load_code(proto, meta, stream)
  local sizecode = stream:read_varint()
  proto.code = {}
  for i=1, sizecode do
    proto.code[i] = Instruction(stream:read_int32(), proto)
  end
end

--- Load a string from the bytecode stream.
-- Reads a size-prefixed string where size==0 indicates nil (absent string)
-- and size>=1 indicates a string of length size-1.
-- @param proto the prototype table
-- @param meta metadata table
-- @param stream the ByteStream to read from
-- @return the decoded string, or nil if absent
local function load_string(proto, meta, stream)
  local size = stream:read_size()
  if size == 0 then
    return nil
  end
  return stream:read_string_vector(size - 1)
end

--- Load the constants (constant pool) section of a function prototype.
-- Reads typed constant values: numbers, integers, strings, booleans, and nil.
-- @param proto the prototype table to populate
-- @param meta metadata table
-- @param stream the ByteStream to read from
local function load_constants(proto, meta, stream)
  local k = {}
  proto.k = k
  for i=1, stream:read_varint() do
    local typetag = stream:read_int8()
    if typetag == typetags.vnumflt.value then
      k[i] = stream:read_number()
    elseif typetag == typetags.vnumint.value then
      k[i] = stream:read_integer()
    elseif typetag == typetags.vsrtstr.value
           or typetag == typetags.vlngstr.value then
      k[i] = load_string(proto, meta, stream)
    else
      assert(typetags[typetag] == typetags.tnil
             or typetags[typetag] == typetags.vtrue
             or typetags[typetag] == typetags.vfalse,
             string.format('typetag was %s (0x%X)', typetags[typetag], typetag))
    end
  end
end

--- Load the upvalue descriptors of a function prototype.
-- Each upvalue has instack, idx, and kind fields.
-- @param proto the prototype table to populate
-- @param meta metadata table
-- @param stream the ByteStream to read from
local function load_upvalues(proto, meta, stream)
  local upvalues = {}
  proto.upvalues = upvalues
  for i=1, stream:read_varint() do
    upvalues[i] = {
      instack = stream:read_int8(),
      idx = stream:read_int8(),
      kind = stream:read_int8(),
    }
  end
end

--- Load nested function prototypes.
-- @param proto the prototype table to populate
-- @param meta metadata table
-- @param stream the ByteStream to read from
local function load_protos(proto, meta, stream)
  proto.p = {}
  for i=1, stream:read_varint() do
    local p = {}
    proto.p[i] = p
    load_function(p, meta, stream)
  end
end

--- Load the debug information section of a function prototype.
-- Includes line info, absolute line info, local variable names, and
-- upvalue names.
-- @param proto the prototype table to populate
-- @param meta metadata table
-- @param stream the ByteStream to read from
local function read_debug(proto, meta, stream)
  proto.sizelineinfo = stream:read_varint()
  proto.lineinfo = stream:read_byte_vector(proto.sizelineinfo)
  proto.sizeabslineinfo = stream:read_varint()
  proto.abslineinfo = {}
  for i = 1, proto.sizeabslineinfo do
    proto.abslineinfo[i] = {
      pc = stream:read_varint(),
      line = stream:read_varint(),
    }
  end
  proto.locvars = {}
  for i=1, stream:read_varint() do
    proto.locvars[i] = {
      varname = load_string(proto, meta, stream),
      startpc = stream:read_varint(),
      endpc = stream:read_varint(),
    }
  end
  for i=1, stream:read_varint() do
    proto.upvalues[i] = proto.upvalues[i] or {}
    proto.upvalues[i].name = load_string(proto, meta, stream)
  end
end

--- Load and validate the bytecode file header.
-- Checks the Lua signature, version, data integrity bytes, and format
-- of integers and floats.
-- @param proto the prototype table to populate
-- @param meta metadata table to populate with size information
-- @param stream the ByteStream to read from
local function load_header(proto, meta, stream)
  local signature = stream:read_literal(#LUA_SIGNATURE)
  assert(signature == LUA_SIGNATURE, 'not a binary chunk')
  local version = stream:read_int8()
  meta.version = {
    major = version & 0xF0 >> 4,
    minor = version & 0x0F,
  }
  proto.format = stream:read_int8()
  assert(stream:read_literal(#LUAC_DATA) == LUAC_DATA, 'corrupted chunk')
  meta.instruction_size = stream:read_int8()
  meta.integer_size = stream:read_int8()
  meta.number_size = stream:read_int8()
  assert(stream:read_integer() == LUAC_INT, 'integer format mismatch')
  assert(stream:read_number() == LUAC_NUM, 'float format mismatch')
end

--- Load a complete function prototype from the bytecode stream.
-- Reads source name, line info, parameters, vararg flag, stack size, and
-- then delegates to loaders for code, constants, upvalues, protos, and debug.
-- @param proto the prototype table to populate
-- @param meta metadata table
-- @param stream the ByteStream to read from
function load_function(proto, meta, stream)
  proto.source = load_string(proto, meta, stream)
  proto.linedefined = stream:read_varint()
  proto.lastlinedefined = stream:read_varint()
  proto.numparams = stream:read_int8()
  proto.flag = stream:read_int8() & PF_ISVARARG -- get only the meaningful flags
  proto.maxstacksize = stream:read_int8()
  load_code(proto, meta, stream)
  load_constants(proto, meta, stream)
  load_upvalues(proto, meta, stream)
  load_protos(proto, meta, stream)
  read_debug(proto, meta, stream)
end

--- Parse a raw bytecode byte string into a prototype and metadata.
-- @param bytes a binary string containing a complete Lua 5.4 compiled chunk
-- @return proto the root function prototype table
-- @return meta metadata table with version, sizes, and string pool
function read_bytes(bytes)
  local proto = {}
  local meta = {}
  local stream = ByteStream(bytes)
  load_header(proto, meta, stream)
  proto.sizeupvalues = stream:read_int8()
  load_function(proto, meta, stream)
  return proto, meta
end

--- Open a file and return its contents as a ByteStream.
-- If the file starts with the Lua signature, it is treated as pre-compiled
-- bytecode. Otherwise it is loaded as Lua source and compiled via
-- loadfile/string.dump.
-- @param filename path to the file to read
-- @return a ByteStream containing the bytecode
function to_bytestream(filename)
  do
    local file <close> = assert(io.open(filename, 'rb'))
    local stream = ByteStream(assert(file:read(4)))

    -- Starting with the Lua signature escape code indicates this is a Lua
    -- bytecode file, so read the whole file into memory so it can be processed.
    local signature = stream:read_literal(#LUA_SIGNATURE)
    if signature == LUA_SIGNATURE then
      file:seek('set', 0)
      local contents = assert(file:read('a'))
      return ByteStream(contents)
    end
  end
  -- This is a Lua source code file, so load and compile the file and dump the
  -- raw bytes so that it can be processed.
  local chunk = assert(loadfile(filename))
  return ByteStream(string.dump(chunk))
end

--- Read and parse a Lua file (source or bytecode) into a prototype.
-- @param filename path to the file to read
-- @return proto the root function prototype table
-- @return meta metadata table
function read_file(filename)
  local proto = {}
  local meta = {}
  local stream = to_bytestream(filename)
  load_header(proto, meta, stream)
  proto.sizeupvalues = stream:read_int8()
  load_function(proto, meta, stream)
  return proto, meta
end

return _M

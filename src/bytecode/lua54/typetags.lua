--- Lua 5.4 type tags for bytecode constants.
-- Defines the base type tags and their variant forms as used in the
-- Lua 5.4 bytecode constant pool. Each tag identifies the type of a
-- constant value stored in a compiled chunk.
-- @module llx.bytecode.lua54.typetags

local environment = require 'llx.environment'
local enum = require 'llx.bytecode.lua54.enum' . enum

local _ENV, _M = environment.create_module_environment()

--- Compute a variant type tag from a base type and variant number.
-- Variants encode subtype information in the upper nibble.
-- @param t the base type tag enum object
-- @param v the variant number
-- @return the combined variant tag value
function makevariant(t, v)
  return t.value | (v << 4)
end

--- Bidirectional enum of all Lua 5.4 type tags and their variants.
-- Base types: tnil, tboolean, tlightuserdata, tnumber, tstring,
-- ttable, tfunction, tuserdata, tthread.
-- Variants include: vnil, vempty, vabstkey, vnotable, vfalse, vtrue,
-- vnumint, vnumflt, vsrtstr, vlngstr, vtable, vlcl, vlcf, vccl, etc.
typetags = enum{
  [0] = 'tnil',
  [1] = 'tboolean',
  [2] = 'tlightuserdata',
  [3] = 'tnumber',
  [4] = 'tstring',
  [5] = 'ttable',
  [6] = 'tfunction',
  [7] = 'tuserdata',
  [8] = 'tthread',
}

typetags:insert(makevariant(typetags.tnil, 0), 'vnil')

typetags:insert(makevariant(typetags.tnil, 1), 'vempty')
typetags:insert(makevariant(typetags.tnil, 2), 'vabstkey')
typetags:insert(makevariant(typetags.tnil, 3), 'vnotable')

typetags:insert(makevariant(typetags.tboolean, 0), 'vfalse')
typetags:insert(makevariant(typetags.tboolean, 1), 'vtrue')

typetags:insert(makevariant(typetags.tlightuserdata, 0), 'vlightuserdata')

typetags:insert(makevariant(typetags.tnumber, 0), 'vnumint')
typetags:insert(makevariant(typetags.tnumber, 1), 'vnumflt')

typetags:insert(makevariant(typetags.tstring, 0), 'vsrtstr')
typetags:insert(makevariant(typetags.tstring, 1), 'vlngstr')

typetags:insert(makevariant(typetags.ttable, 0), 'vtable')

typetags:insert(makevariant(typetags.tfunction, 0), 'vlcl') -- Lua closure
typetags:insert(makevariant(typetags.tfunction, 1), 'vlcf') -- light C function
typetags:insert(makevariant(typetags.tfunction, 2), 'vccl') -- C closure

typetags:insert(makevariant(typetags.tuserdata, 0), 'vuserdata')

typetags:insert(makevariant(typetags.tthread, 0), 'vthread')

return _M

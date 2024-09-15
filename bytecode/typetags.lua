local enum = require 'enum'

function makevariant(t, v)
  return t.value | (v << 4)
end

typetags = enum.enum{
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

return {
  typetags = typetags
}
--- Bytecode parsing module.
-- Provides access to version-specific bytecode parsers.
-- Supports Lua 5.4 and 5.5. Top-level exports (read_bytes, read_file,
-- etc.) are dispatched to the parser matching the running Lua version.
-- Version-specific parsers are also available as bytecode.lua54 and
-- bytecode.lua55.
--
-- On a Lua version with no matching parser (e.g. 5.3), the module still
-- loads: the version-specific parsers remain usable for chunks in those
-- formats, and the auto-dispatched top-level readers raise a clear error
-- only if actually called.
-- @module llx.bytecode

local version_modules = {
  ['Lua 5.4'] = 'llx.bytecode.lua54',
  ['Lua 5.5'] = 'llx.bytecode.lua55',
}

local lua54 = require 'llx.bytecode.lua54'
local lua55 = require 'llx.bytecode.lua55'

local current_module = version_modules[_VERSION]

if current_module then
  return require 'llx.flatten_submodules' {
    require(current_module),
    lua54 = lua54,
    lua55 = lua55,
  }
end

-- No parser matches the running Lua version. Keep the top-level API surface
-- present but deferred-erroring, so `require 'llx'` succeeds and the failure
-- (if any) points the caller at the explicit parsers.
local function unsupported()
  error(string.format(
    '%s has no matching bytecode parser; use llx.bytecode.lua54 or '
    .. 'llx.bytecode.lua55 explicitly', _VERSION), 2)
end

return require 'llx.flatten_submodules' {
  {
    read_bytes = unsupported,
    read_file = unsupported,
    to_bytestream = unsupported,
  },
  lua54 = lua54,
  lua55 = lua55,
}

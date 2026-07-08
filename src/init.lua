-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local strict = require 'llx.strict'
local flatten_submodules = require 'llx.flatten_submodules'

-- Lock the global table while the submodules load so that an accidental
-- global assignment in any module surfaces immediately, then unlock once
-- loading finishes. The loads run under pcall so the table is always
-- unlocked, even if a module raises. This deliberately avoids the 5.4-only
-- <close> attribute so the entry point still parses on Lua 5.3.
local lock = strict.lock_global_table()
local unlock = getmetatable(lock).__close

local ok, result = pcall(function()
  return flatten_submodules {
    require 'llx.check_arguments',
    require 'llx.class',
    require 'llx.collections',
    require 'llx.core',
    require 'llx.dataclass',
    require 'llx.enum',
    require 'llx.getclass',
    require 'llx.hash_table',
    require 'llx.is_subtype',
    require 'llx.isinstance',
    require 'llx.namedtuple',
    require 'llx.repr',
    require 'llx.result',
    require 'llx.seq',
    require 'llx.schema',
    require 'llx.strict',
    require 'llx.string_view',
    require 'llx.tointeger',
    require 'llx.tostringf',
    require 'llx.tuple',
    require 'llx.types',
    bisect = require 'llx.bisect',
    contextlib = require 'llx.contextlib',
    coroutine = require 'llx.coroutine',
    debug = require 'llx.debug',
    decorator = require 'llx.decorator',
    environment = require 'llx.environment',
    exceptions = require 'llx.exceptions',
    export = require 'llx.export',
    flow_control = require 'llx.flow_control',
    functional = require 'llx.functional',
    hash = require 'llx.hash',
    mathx = require 'llx.mathx',
    path = require 'llx.path',
    pretty = require 'llx.pretty',
    method = require 'llx.method',
    operators = require 'llx.operators',
    property = require 'llx.property',
    proxy = require 'llx.proxy',
    truthy = require 'llx.truthy',
    type_check_decorator = require 'llx.type_check_decorator',
    bytecode = require 'llx.bytecode',
  }
end)

unlock(lock)

if not ok then
  error(result, 0)
end

return result

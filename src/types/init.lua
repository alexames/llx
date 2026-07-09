-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

-- The Tuple matcher shares its name with the llx.Tuple value class
-- (src/tuple.lua). The value class owns the top-level name when llx
-- flattens its submodules (flatten_submodules rejects duplicate
-- keys), so the matcher is excluded here and stays reachable via
-- require 'llx.types.matchers'.
local matchers = require 'llx.types.matchers'
local matcher_exports = {}
for key, value in pairs(matchers) do
  if key ~= 'Tuple' then
    matcher_exports[key] = value
  end
end

return require 'llx.flatten_submodules' {
  require 'llx.types.boolean',
  require 'llx.types.float',
  require 'llx.types.function',
  require 'llx.types.integer',
  require 'llx.types.nil',
  require 'llx.types.number',
  require 'llx.types.string',
  require 'llx.types.table',
  require 'llx.types.thread',
  require 'llx.types.userdata',

  require 'llx.types.list',
  require 'llx.types.set',

  matcher_exports
}

-- Aggregate test runner. Runs the full llx test suite directly from
-- a source checkout:
--
--   lua test.lua
--
-- The rockspec installs only llx.* (from src/); nothing installs or
-- maps llx.tests.*. The searcher below resolves llx.* from src/ and
-- llx.tests.* from tests/, relative to this file, so the aggregate
-- run needs no installation or LUA_PATH setup and always tests the
-- checkout it lives in (issue #71).

local root = (arg and arg[0] or ''):match('^(.*[/\\])') or ''

-- Tries `<root><dir>/<rel>.lua`, then `<root><dir>/<rel>/init.lua`.
-- Returns a loader and the path on success, or the accumulated error
-- text in the format require expects from a failed searcher. A file
-- that exists but fails to compile raises immediately (like the
-- standard searcher) so a broken checkout file can never be silently
-- shadowed by an installed copy of llx later in the search order.
local function load_from(dir, rel)
  local base = root .. dir .. '/' .. rel:gsub('%.', '/')
  local errors = {}
  for _, path in ipairs({base .. '.lua', base .. '/init.lua'}) do
    local file = io.open(path, 'r')
    if file then
      file:close()
      local chunk, err = loadfile(path)
      if not chunk then
        error(err, 0)
      end
      return chunk, path
    end
    errors[#errors + 1] = "\n\tno file '" .. path .. "'"
  end
  return table.concat(errors)
end

local function checkout_searcher(name)
  if name == 'llx' then
    return load_from('src', 'init')
  end
  if name == 'llx.tests' then
    return load_from('tests', 'init')
  end
  local rest = name:match('^llx%.tests%.(.+)$')
  if rest then
    return load_from('tests', rest)
  end
  rest = name:match('^llx%.(.+)$')
  if rest then
    return load_from('src', rest)
  end
  return nil
end

-- Insert right after package.preload so the checkout takes priority
-- over any previously installed copy of llx.
table.insert(package.searchers, 2, checkout_searcher)

local unit = require 'llx.unit'
require 'llx.tests'

os.exit(unit.run_unit_tests() == 0)

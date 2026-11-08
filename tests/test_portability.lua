-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- Holds every source in the checkout to the Lua versions that load it,
-- so a change that only one interpreter can parse fails on whichever
-- interpreter runs the suite. Shared code must parse on Lua 5.1 and
-- LuaJIT and reach version-specific library names only through
-- llx.compat; the files listed in FLOORS load on fewer interpreters
-- and may use what those interpreters provide.

local compat = require 'llx.compat'
local llx = require 'llx'
local unit = require 'llx.unit'

local _ENV = unit.create_test_env(_ENV)

-- The checkout root, with a trailing separator, derived from this
-- file's own path so the aggregate and per-file runs agree.
local function checkout_root()
  local source = debug.getinfo(1, 'S').source
  local path = source:match('^@(.*)$') or source
  local dir = path:match('^(.*[/\\])') or './'
  return dir .. '../'
end

-- Loaded by path rather than required: a per-file run resolves only
-- the installed llx.* modules, not llx.tests.*.
local lua_features =
    dofile(checkout_root() .. 'tests/support/lua_features.lua')

local ALL = lua_features.TARGETS
local LUA51_FAMILY = {'5.1', 'luajit'}
local FROM_52 = {'5.2', '5.3', '5.4', '5.5'}
local FROM_53 = {'5.3', '5.4', '5.5'}

-- Path prefixes, relative to the checkout root, of the sources that
-- load on only some interpreters, with the interpreters they load on.
-- The first matching prefix wins; everything else loads everywhere.
local FLOORS = {
  {'src/compat/portable.lua', ALL},
  {'src/compat/lua51.lua', LUA51_FAMILY},
  {'src/compat/luajit.lua', {'luajit'}},
  {'src/compat/lua52.lua', FROM_52},
  {'src/compat/lua53.lua', FROM_53},
  {'src/bytecode/lua54/', FROM_53},
  {'src/bytecode/lua55/', FROM_53},
  {'tests/bytecode/', FROM_53},
  {'tests/lua53/', FROM_53},
}

-- Sources allowed to name version-specific library functions without
-- going through llx.compat, and which names. src/compat is where those
-- names live. test.lua installs the searcher llx.compat is loaded
-- through, so it cannot use it, and spells `package.searchers or
-- package.loaders` itself.
local LIBRARY_EXEMPT_PREFIXES = {'src/compat/', 'src/bytecode/',
                                 'tests/bytecode/'}
local LIBRARY_EXEMPT_NAMES = {
  ['test.lua'] = {['package.searchers'] = true, ['package.loaders'] = true},
}

-- Every .lua file under src/ and tests/, plus test.lua, as paths
-- relative to the checkout root with forward slashes, sorted.
local function lua_sources(root)
  local is_windows = package.config:sub(1, 1) == '\\'
  local files = {'test.lua'}
  for _, top in ipairs({'src', 'tests'}) do
    local command
    if is_windows then
      local dir = (root .. top):gsub('/', '\\')
      command = 'dir /b /s "' .. dir .. '\\*.lua" 2>nul'
    else
      command = 'find "' .. root .. top .. '" -name "*.lua" 2>/dev/null'
    end
    local handle = io.popen(command)
    if handle then
      for line in handle:lines() do
        local normalized = line:gsub('\\', '/')
        local relative = normalized:match('/(' .. top .. '/.*)$')
        if relative then
          table.insert(files, relative)
        end
      end
      handle:close()
    end
  end
  table.sort(files)
  return files
end

local function starts_with(text, prefix)
  return text:sub(1, #prefix) == prefix
end

local function targets_for(path)
  for _, floor in ipairs(FLOORS) do
    if starts_with(path, floor[1]) then
      return floor[2]
    end
  end
  return ALL
end

local function library_exempt(path, feature)
  for _, prefix in ipairs(LIBRARY_EXEMPT_PREFIXES) do
    if starts_with(path, prefix) then return true end
  end
  local names = LIBRARY_EXEMPT_NAMES[path]
  return names ~= nil and names[feature] == true
end

-- Syntax a Lua cannot parse fails the file on that Lua; a library name
-- it lacks fails the file only where llx.compat should have been used.
local SYNTAX_FEATURES = {
  ['goto'] = true, ['label'] = true, ['escape \\x'] = true,
  ['escape \\z'] = true, ['escape \\u{}'] = true,
  ['hexadecimal float'] = true, ['operator //'] = true,
  ['operator &'] = true, ['operator |'] = true, ['operator ~'] = true,
  ['operator <<'] = true, ['operator >>'] = true, ['attribute'] = true,
}

local function violations(root)
  local found = {}
  for _, path in ipairs(lua_sources(root)) do
    local handle = io.open(root .. path, 'rb')
    local source = handle:read('*a')
    handle:close()
    local ok, features = pcall(lua_features.scan, source)
    if not ok then
      table.insert(found, path .. ': ' .. tostring(features))
    else
      for _, record in ipairs(features) do
        local is_syntax = SYNTAX_FEATURES[record.feature]
        if is_syntax or not library_exempt(path, record.feature) then
          for _, target in ipairs(targets_for(path)) do
            if not lua_features.supports(record.feature, target) then
              table.insert(found, string.format('%s:%d: %s (Lua %s)',
                  path, record.line, record.feature, target))
            end
          end
        end
      end
    end
  end
  return found
end

-- The build.modules table a rockspec declares, read in an empty
-- environment; nil and a message when it cannot be read.
local function rockspec_modules(path)
  local spec = {}
  local chunk, load_error = compat.loadfile(path, 't', spec)
  if not chunk then return nil, tostring(load_error) end
  local ran, run_error = pcall(chunk)
  if not ran then return nil, tostring(run_error) end
  return spec.build and spec.build.modules
end

local function sorted_entries(modules)
  local entries = {}
  for name, path in compat.pairs(modules or {}) do
    table.insert(entries, name .. '=' .. path)
  end
  table.sort(entries)
  return table.concat(entries, '\n')
end

describe('portability', function()
  it('should ship the same modules from both rockspecs', function()
    local root = checkout_root()
    local lua_modules = rockspec_modules(root .. 'llx-scm-1.rockspec')
    local luajit_modules =
        rockspec_modules(root .. 'llx-luajit-scm-1.rockspec')
    expect(lua_modules).to_not.be_nil()
    expect(sorted_entries(luajit_modules))
      .to.be_equal_to(sorted_entries(lua_modules))
  end)

  it('should ship every source under src', function()
    local root = checkout_root()
    local shipped = {}
    for _, path in compat.pairs(rockspec_modules(
        root .. 'llx-scm-1.rockspec') or {}) do
      shipped[path] = true
    end
    local missing = {}
    for _, path in ipairs(lua_sources(root)) do
      if starts_with(path, 'src/') and not shipped[path] then
        table.insert(missing, path)
      end
    end
    expect(table.concat(missing, ', ')).to.be_equal_to('')
  end)

  it('should find the sources', function()
    local files = lua_sources(checkout_root())
    expect(#files > 100).to.be_true()
  end)

  it('should hold every source to the Lua versions that load it',
      function()
    expect(table.concat(violations(checkout_root()), '\n'))
      .to.be_equal_to('')
  end)

  describe('the lexer', function()
    local function features_of(source)
      local names = {}
      for _, record in ipairs(lua_features.scan(source)) do
        table.insert(names, record.feature)
      end
      return table.concat(names, ',')
    end

    it('should report the integer operators', function()
      expect(features_of('local x = a // b & c | d ~ e << 1 >> 2'))
        .to.be_equal_to('operator //,operator &,operator |,operator ~,'
                        .. 'operator <<,operator >>')
    end)

    it('should not mistake ~= for ~', function()
      expect(features_of('return a ~= b')).to.be_equal_to('')
    end)

    it('should ignore operators inside strings and comments', function()
      expect(features_of("local s = 'a // b' -- c | d\n--[[ e & f ]]"))
        .to.be_equal_to('')
    end)

    it('should report goto, labels and attributes', function()
      expect(features_of('goto done ::done:: local x <const> = 1'))
        .to.be_equal_to('goto,label,attribute')
    end)

    it('should report version-specific library names', function()
      expect(features_of('table.unpack(t) math.type(1) setfenv(1, {})'))
        .to.be_equal_to('table.unpack,math.type,setfenv')
    end)

    it('should not report a table key or a local declaration', function()
      expect(features_of('local t = {unpack = 1} local load = 2'))
        .to.be_equal_to('')
    end)
  end)
end)

if llx.main_file() then
  os.exit(unit.run_unit_tests() == 0 and 0 or 1)
end

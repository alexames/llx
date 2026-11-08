-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- A Lua lexer that reports the version-specific syntax and standard
-- library names a source file uses, so a test can hold each file to
-- the Lua versions it is loaded on without running those versions.
-- Written in the Lua 5.1 subset so it runs on every supported
-- interpreter.

local M = {}

--- Every target the portability check knows, oldest first.
M.TARGETS = {'5.1', 'luajit', '5.2', '5.3', '5.4', '5.5'}

local ALL = {}
for _, target in ipairs(M.TARGETS) do ALL[target] = true end

local function targets(...)
  local set = {}
  for i = 1, select('#', ...) do set[select(i, ...)] = true end
  return set
end

local FROM_52 = targets('luajit', '5.2', '5.3', '5.4', '5.5')
local FROM_53_PUC = targets('5.3', '5.4', '5.5')
local FROM_52_PUC = targets('5.2', '5.3', '5.4', '5.5')
local ONLY_51 = targets('5.1', 'luajit')

--- The targets that support each feature the lexer reports. A feature
-- absent from this table is supported everywhere.
M.SUPPORTED_BY = {
  ['goto'] = FROM_52,
  ['label'] = FROM_52,
  ['escape \\x'] = FROM_52,
  ['escape \\z'] = FROM_52,
  ['escape \\u{}'] = targets('luajit', '5.3', '5.4', '5.5'),
  ['hexadecimal float'] = FROM_52,
  ['operator //'] = FROM_53_PUC,
  ['operator &'] = FROM_53_PUC,
  ['operator |'] = FROM_53_PUC,
  ['operator ~'] = FROM_53_PUC,
  ['operator <<'] = FROM_53_PUC,
  ['operator >>'] = FROM_53_PUC,
  ['attribute'] = targets('5.4', '5.5'),
  -- Standard library names. LuaJIT is held to its default build:
  -- table.pack, table.unpack and rawlen exist there only when it is
  -- built with LUAJIT_ENABLE_LUA52COMPAT.
  ['table.pack'] = FROM_52_PUC,
  ['table.unpack'] = FROM_52_PUC,
  ['rawlen'] = FROM_52_PUC,
  ['package.searchers'] = FROM_52_PUC,
  ['math.type'] = FROM_53_PUC,
  ['math.tointeger'] = FROM_53_PUC,
  ['math.maxinteger'] = FROM_53_PUC,
  ['math.mininteger'] = FROM_53_PUC,
  ['string.pack'] = FROM_53_PUC,
  ['string.unpack'] = FROM_53_PUC,
  ['string.packsize'] = FROM_53_PUC,
  ['utf8'] = FROM_53_PUC,
  ['bit32'] = targets('5.2'),
  ['bit'] = targets('luajit'),
  ['ffi'] = targets('luajit'),
  ['setfenv'] = ONLY_51,
  ['getfenv'] = ONLY_51,
  ['loadstring'] = ONLY_51,
  ['unpack'] = ONLY_51,
  ['package.loaders'] = ONLY_51,
  ['load'] = FROM_52,
  ['read format without *'] = FROM_53_PUC,
}

-- Library fields whose access is reported as `<library>.<field>`.
local LIBRARY_FIELDS = {
  table = {pack = true, unpack = true},
  package = {searchers = true, loaders = true},
  math = {type = true, tointeger = true, maxinteger = true,
          mininteger = true},
  string = {pack = true, unpack = true, packsize = true},
}

-- Global names reported when used as a bare name rather than a field.
local GLOBALS = {
  rawlen = true, utf8 = true, bit32 = true, bit = true, ffi = true,
  setfenv = true, getfenv = true, loadstring = true, unpack = true,
  load = true,
}

local KEYWORDS = {}
for word in ([[and break do else elseif end false for function goto if
    in local nil not or repeat return then true until while]]):gmatch('%a+') do
  KEYWORDS[word] = true
end

-- Longest first, so a two-character operator is never split.
local OPERATORS = {
  '...', '..', '==', '~=', '<=', '>=', '<<', '>>', '//', '::',
}

local function new_lexer(source)
  return {source = source, pos = 1, line = 1, tokens = {}, features = {}}
end

local function note(lexer, feature, line)
  table.insert(lexer.features, {feature = feature, line = line or lexer.line})
end

local function count_newlines(text)
  local _, n = text:gsub('\n', '')
  return n
end

-- Reads a long bracket starting at `pos`, which holds `[`. Returns the
-- position just past it, or nil when `pos` does not open one.
local function long_bracket_end(lexer, pos)
  local equals = lexer.source:match('^%[(=*)%[', pos)
  if not equals then return nil end
  local close = ']' .. equals .. ']'
  local _, finish = lexer.source:find(close, pos + #equals + 2, true)
  if not finish then
    error(string.format('line %d: unfinished long bracket', lexer.line))
  end
  return finish + 1
end

local function read_quoted(lexer, quote)
  local source, pos = lexer.source, lexer.pos + 1
  while true do
    local c = source:sub(pos, pos)
    if c == '' or c == '\n' then
      error(string.format('line %d: unfinished string', lexer.line))
    elseif c == quote then
      lexer.pos = pos + 1
      return
    elseif c == '\\' then
      local escape = source:sub(pos + 1, pos + 1)
      if escape == 'x' then
        note(lexer, 'escape \\x')
      elseif escape == 'z' then
        note(lexer, 'escape \\z')
        local skipped = source:match('^%s*', pos + 2)
        lexer.line = lexer.line + count_newlines(skipped)
        pos = pos + #skipped
      elseif escape == 'u' then
        note(lexer, 'escape \\u{}')
      elseif escape == '\n' then
        lexer.line = lexer.line + 1
      end
      pos = pos + 2
    else
      pos = pos + 1
    end
  end
end

local function read_number(lexer)
  local source, pos = lexer.source, lexer.pos
  local hex = source:match('^0[xX]%x*%.?%x*', pos)
  if hex then
    local exponent = source:match('^[pP][+-]?%d+', pos + #hex) or ''
    if hex:find('.', 1, true) or exponent ~= '' then
      note(lexer, 'hexadecimal float')
    end
    lexer.pos = pos + #hex + #exponent
    return
  end
  local decimal = source:match('^%d*%.?%d*', pos)
  local exponent = source:match('^[eE][+-]?%d+', pos + #decimal) or ''
  lexer.pos = pos + #decimal + #exponent
end

local function push(lexer, kind, value)
  table.insert(lexer.tokens, {kind = kind, value = value, line = lexer.line})
end

local function tokenize(lexer)
  local source = lexer.source
  if source:sub(1, 1) == '#' then
    lexer.pos = (source:find('\n', 1, true) or #source + 1)
  end
  while lexer.pos <= #source do
    local pos = lexer.pos
    local c = source:sub(pos, pos)
    if c == '\n' then
      lexer.line = lexer.line + 1
      lexer.pos = pos + 1
    elseif c:match('%s') then
      lexer.pos = pos + 1
    elseif source:sub(pos, pos + 1) == '--' then
      local finish = long_bracket_end(lexer, pos + 2)
      if finish then
        lexer.line = lexer.line + count_newlines(source:sub(pos, finish - 1))
        lexer.pos = finish
      else
        lexer.pos = source:find('\n', pos, true) or #source + 1
      end
    elseif c == '[' and long_bracket_end(lexer, pos) then
      local finish = long_bracket_end(lexer, pos)
      push(lexer, 'string')
      lexer.line = lexer.line + count_newlines(source:sub(pos, finish - 1))
      lexer.pos = finish
    elseif c == '"' or c == "'" then
      -- The value is the first character only, enough to tell a read
      -- format such as 'a' from '*a'.
      push(lexer, 'string', source:sub(pos + 1, pos + 1))
      read_quoted(lexer, c)
    elseif c:match('%d')
        or (c == '.' and source:sub(pos + 1, pos + 1):match('%d')) then
      push(lexer, 'number')
      read_number(lexer)
    elseif c:match('[%a_]') then
      local name = source:match('^[%w_]+', pos)
      push(lexer, KEYWORDS[name] and 'keyword' or 'name', name)
      lexer.pos = pos + #name
    else
      local operator = c
      for _, candidate in ipairs(OPERATORS) do
        if source:sub(pos, pos + #candidate - 1) == candidate then
          operator = candidate
          break
        end
      end
      push(lexer, 'operator', operator)
      lexer.pos = pos + #operator
    end
  end
end

local INTEGER_OPERATORS = {
  ['//'] = true, ['&'] = true, ['|'] = true, ['~'] = true,
  ['<<'] = true, ['>>'] = true,
}

-- Names the chunk declares `local` anywhere, so a use of a local named
-- like a global (`local unpack = compat.unpack`) is not reported. Scope
-- is ignored: a name declared local anywhere is taken as local
-- everywhere in the chunk.
local function declared_locals(tokens)
  local names = {}
  for i, token in ipairs(tokens) do
    if token.kind == 'keyword' and token.value == 'local' then
      local j = i + 1
      if tokens[j] and tokens[j].value == 'function' then
        j = j + 1
      end
      while tokens[j] and tokens[j].kind == 'name' do
        names[tokens[j].value] = true
        if not (tokens[j + 1] and tokens[j + 1].value == ',') then break end
        j = j + 2
      end
    end
  end
  return names
end

local function classify(lexer)
  local tokens = lexer.tokens
  local locals = declared_locals(tokens)
  for i, token in ipairs(tokens) do
    local previous, following = tokens[i - 1], tokens[i + 1]
    local after_dot = previous and previous.kind == 'operator'
        and (previous.value == '.' or previous.value == ':')
    if token.kind == 'keyword' and token.value == 'goto' then
      note(lexer, 'goto', token.line)
    elseif token.kind == 'operator' then
      if token.value == '::' then
        -- Reported once per label, at its opening `::`.
        if following and following.kind == 'name' and tokens[i + 2]
            and tokens[i + 2].value == '::' then
          note(lexer, 'label', token.line)
        end
      elseif INTEGER_OPERATORS[token.value] then
        note(lexer, 'operator ' .. token.value, token.line)
      elseif token.value == '<' and previous and previous.kind == 'name'
          and following and following.kind == 'name'
          and (following.value == 'const' or following.value == 'close')
          and tokens[i + 2] and tokens[i + 2].value == '>' then
        note(lexer, 'attribute', token.line)
      end
    elseif token.kind == 'name' and not after_dot then
      local fields = LIBRARY_FIELDS[token.value]
      local field = tokens[i + 2]
      if fields and following and following.value == '.'
          and field and fields[field.value] then
        note(lexer, token.value .. '.' .. field.value, token.line)
      elseif GLOBALS[token.value] and not locals[token.value] then
        -- `local unpack = ...` declares a name and `{unpack = ...}` is a
        -- table key; neither uses the global.
        local declares = previous and previous.value == 'local'
        local is_key = following and following.value == '='
            and previous and (previous.value == '{' or previous.value == ','
                              or previous.value == ';')
        if not (declares or is_key) then
          note(lexer, token.value, token.line)
        end
      end
    end
    if token.kind == 'name' and after_dot and previous.value == ':'
        and (token.value == 'read' or token.value == 'lines') then
      -- 5.1 requires the `*` in '*a', '*l' and '*n'; 5.3 made it optional.
      local open, argument = following, tokens[i + 2]
      if open and open.value == '(' and argument
          and argument.kind == 'string' and argument.value
          and argument.value:match('^[alnL]') then
        note(lexer, 'read format without *', token.line)
      end
    end
  end
end

--- Lexes a Lua source and lists the version-specific features it uses.
-- @param source The full text of a Lua chunk.
-- @return A list of `{feature = name, line = n}` records in source
--   order; the names are the keys of SUPPORTED_BY. Raises on a string
--   or long bracket that never closes.
function M.scan(source)
  local lexer = new_lexer(source)
  tokenize(lexer)
  classify(lexer)
  return lexer.features
end

--- Whether a target supports a feature.
-- @param feature A feature name as reported by scan.
-- @param target One of TARGETS.
-- @return true when the target parses or provides the feature.
function M.supports(feature, target)
  local supported = M.SUPPORTED_BY[feature]
  return supported == nil or supported[target] == true
end

M.ALL_TARGETS = ALL

return M

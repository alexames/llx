-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Pretty-printer for Lua values.
--
-- Like `repr`, but multi-line with indentation when a value
-- wouldn't fit on a single line, with cycle detection so
-- self-referential tables don't blow the stack, and with
-- deterministic key ordering so output is stable across runs.
--
-- Respects __tostring on metatables of custom types (classes,
-- enums, etc.) — they render via their own format rather than
-- being expanded structurally.
-- @module llx.pretty

local core = require 'llx.core'
local environment = require 'llx.environment'

local _ENV, _M = environment.create_module_environment()

local getmetafield = core.getmetafield

local IDENTIFIER_PATTERN = '^[%a_][%w_]*$'

-- Reserved words that look like identifiers but aren't safe to
-- use as bare keys in a Lua table constructor. We render those
-- as ["word"] = value instead of word = value.
local RESERVED = {
  ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true,
  ['elseif'] = true, ['end'] = true, ['false'] = true, ['for'] = true,
  ['function'] = true, ['goto'] = true, ['if'] = true, ['in'] = true,
  ['local'] = true, ['nil'] = true, ['not'] = true, ['or'] = true,
  ['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true,
  ['until'] = true, ['while'] = true,
}

local function is_simple_key(k)
  return type(k) == 'string'
      and k:find(IDENTIFIER_PATTERN) ~= nil
      and not RESERVED[k]
end

local function format_primitive(v)
  local t = type(v)
  if t == 'nil' then return 'nil' end
  if t == 'boolean' then return tostring(v) end
  if t == 'string' then return string.format('%q', v) end
  if t == 'number' then
    if v ~= v then return 'nan' end
    if v == math.huge then return 'math.huge' end
    if v == -math.huge then return '-math.huge' end
    if math.type(v) == 'integer' then return tostring(v) end
    return tostring(v)
  end
  -- function, thread, userdata: fall back to tostring; not
  -- recursively pretty-printable.
  return tostring(v)
end

-- Sort comparator for table keys: type-bucketed, then by value
-- within each bucket. Mixed-type key sets are common (e.g. a
-- list with stray string keys), so we partition by type to
-- avoid invalid comparisons (`1 < 'a'` raises).
local TYPE_ORDER = {
  ['boolean'] = 1, ['number'] = 2, ['string'] = 3,
  ['function'] = 4, ['userdata'] = 5, ['thread'] = 6, ['table'] = 7,
}
local function key_less(a, b)
  local ta, tb = type(a), type(b)
  if ta ~= tb then return TYPE_ORDER[ta] < TYPE_ORDER[tb] end
  if ta == 'boolean' or ta == 'number' or ta == 'string' then
    return a < b
  end
  -- For non-comparable types, fall back to tostring.
  return tostring(a) < tostring(b)
end

--- Computes the key prefix ('foo = ' or '[1.5] = ') for a
-- non-sequence entry, or '' for a sequence entry.
local function key_prefix(entry)
  if entry.is_seq then return '' end
  if is_simple_key(entry.key) then
    return entry.key .. ' = '
  end
  return '[' .. format_primitive(entry.key) .. '] = '
end

--- Internal recursive walker.
-- @param value Value to format
-- @param opts {indent, width, max_depth}
-- @param depth Current depth
-- @param visited Map of table -> marker for cycle detection
-- @param indent_str Current indentation prefix
-- @param available How many columns are left on the current line
--   for this value if it stays inline. Used to decide multi-line
--   breaks, which is more accurate than checking just the value's
--   own length because a key prefix on the parent line counts
--   against the value's budget.
-- @return formatted string
local function format_impl(value, opts, depth, visited, indent_str, available)
  local t = type(value)
  if t ~= 'table' then
    return format_primitive(value)
  end

  -- Respect __tostring on metatable: classes, enums, namedtuples
  -- etc. usually want their own rendering rather than structural
  -- expansion. Use getmetafield (debug.getmetatable under the
  -- hood) so __metatable-overridden classes still work, since
  -- llx's class system sets __metatable to a proxy.
  if type(getmetafield(value, '__tostring')) == 'function' then
    return tostring(value)
  end

  if visited[value] then
    return '<cycle>'
  end

  if opts.max_depth and depth >= opts.max_depth then
    return '{...}'
  end

  visited[value] = true

  -- Collect entries: sequence portion in order, then sorted rest.
  local entries = {}
  local n = #value
  for i = 1, n do
    entries[#entries + 1] = {key = i, value = value[i], is_seq = true}
  end
  local rest_keys = {}
  for k in pairs(value) do
    if not (type(k) == 'number'
            and math.type(k) == 'integer'
            and k >= 1 and k <= n) then
      rest_keys[#rest_keys + 1] = k
    end
  end
  table.sort(rest_keys, key_less)
  for _, k in ipairs(rest_keys) do
    entries[#entries + 1] = {key = k, value = value[k], is_seq = false}
  end

  if #entries == 0 then
    visited[value] = nil
    return '{}'
  end

  local child_indent = indent_str .. opts.indent

  -- Pass 1: try fully inline. Render each child with unlimited
  -- width so we can check the assembled length.
  local inline_parts = {}
  for i, e in ipairs(entries) do
    local prefix = key_prefix(e)
    local rendered =
      format_impl(e.value, opts, depth + 1, visited, child_indent, math.huge)
    inline_parts[i] = prefix .. rendered
  end
  local inline = '{' .. table.concat(inline_parts, ', ') .. '}'
  if #inline <= available and not inline:find('\n', 1, true) then
    visited[value] = nil
    return inline
  end

  -- Pass 2: multi-line. Re-render each child with the correct
  -- per-line budget so deeply-nested values can break too.
  local lines = {'{'}
  for i, e in ipairs(entries) do
    local prefix = key_prefix(e)
    local child_available = opts.width - #child_indent - #prefix
    local rendered =
      format_impl(e.value, opts, depth + 1, visited,
                  child_indent, child_available)
    local sep = i < #entries and ',' or ''
    lines[#lines + 1] = child_indent .. prefix .. rendered .. sep
  end
  lines[#lines + 1] = indent_str .. '}'

  visited[value] = nil
  return table.concat(lines, '\n')
end

local DEFAULT_OPTS = {
  indent = '  ',
  width = 80,
  max_depth = nil,
}

local function resolve_opts(opts)
  if opts == nil then return DEFAULT_OPTS end
  local result = {}
  for k, v in pairs(DEFAULT_OPTS) do result[k] = v end
  for k, v in pairs(opts) do result[k] = v end
  return result
end

--- Returns a pretty-printed string representation of any Lua value.
-- @param value The value to format
-- @param opts Optional: {indent='  ', width=80, max_depth=nil}
-- @return A formatted string
function format(value, opts)
  local resolved = resolve_opts(opts)
  return format_impl(value, resolved, 0, {}, '', resolved.width)
end

--- Pretty-prints a value followed by a newline.
-- Named `pprint` rather than `print` to avoid shadowing Lua's
-- global print inside this module.
-- @param value The value to print
-- @param opts Same options as format
function pprint(value, opts)
  io.write(format(value, opts), '\n')
end

return _M

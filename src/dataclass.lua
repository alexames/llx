-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>

--- Auto-generated record classes with named fields.
--
-- `dataclass(name, fields, opts?)` returns a class whose instances
-- accept positional or keyword arguments, support defaults, compare
-- structurally, hash by value, and tostring to a readable form.
--
-- The difference from `namedtuple`:
-- - dataclass fields have NAMED access (`p.x`, `p.y`) rather than
--   positional (`p[1]`, `p[2]`).
-- - dataclass fields can have default values.
-- - dataclass instances are mutable by default. Pass
--   `{immutable = true}` as opts to lock them.
-- - dataclass accepts both `Point(3, 4)` and `Point{x=3, y=4}`.
-- - dataclass supports field type annotations (used only for
--   documentation today; type-checking is planned).
--
-- Field spec:
--     {
--       {name = 'x', type = Integer},
--       {name = 'y', type = Integer, default = 0},
--     }
-- @module llx.dataclass

local class_module = require 'llx.class'
local environment = require 'llx.environment'
local exceptions = require 'llx.exceptions'

local _ENV, _M = environment.create_module_environment()

local class = class_module.class

--- Creates a new dataclass.
-- @param name The class name (string)
-- @param fields List of field specs: each {name=, type=?, default=?}
-- @param opts Optional: {immutable = boolean}
-- @return A class. Instances accept positional or keyword args.
function dataclass(name, fields, opts)
  if type(name) ~= 'string' then
    error('dataclass: name must be a string', 2)
  end
  if type(fields) ~= 'table' then
    error('dataclass: fields must be a list of field specs', 2)
  end
  opts = opts or {}
  local immutable = opts.immutable == true

  local n_fields = #fields
  local field_names = {}
  local field_index = {}
  local field_types = {}
  local field_defaults = {}
  local has_defaults = {}
  for i, f in ipairs(fields) do
    if type(f) ~= 'table' or type(f.name) ~= 'string' then
      error('dataclass: each field must be {name = string, ...}', 2)
    end
    if field_index[f.name] then
      error('dataclass: duplicate field name "' .. f.name .. '"', 2)
    end
    field_names[i] = f.name
    field_index[f.name] = i
    field_types[f.name] = f.type
    if f.default ~= nil then
      field_defaults[f.name] = f.default
      has_defaults[f.name] = true
    end
  end

  -- Decide whether a single-table argument is keyword-form (i.e.
  -- has any string key matching a declared field) versus a value
  -- that happens to be a table being passed positionally.
  local function looks_like_kwargs(t)
    if type(t) ~= 'table' then return false end
    for k in pairs(t) do
      if type(k) == 'string' and field_index[k] ~= nil then
        return true
      end
    end
    return false
  end

  -- Build the {name -> value} table from positional or kwargs args.
  local function build_values(...)
    local n = select('#', ...)
    local values = {}
    if n == 1 and looks_like_kwargs((select(1, ...))) then
      local kwargs = (select(1, ...))
      for i = 1, n_fields do
        local fname = field_names[i]
        local v = kwargs[fname]
        if v == nil then v = field_defaults[fname] end
        if v == nil and not has_defaults[fname] then
          error(string.format(
            '%s: missing required field "%s"', name, fname), 4)
        end
        values[fname] = v
      end
    else
      for i = 1, n_fields do
        local v = select(i, ...)
        if v == nil then v = field_defaults[field_names[i]] end
        if v == nil and not has_defaults[field_names[i]] then
          error(string.format(
            '%s: missing required field "%s" (positional arg %d)',
            name, field_names[i], i), 4)
        end
        values[field_names[i]] = v
      end
    end
    return values
  end

  local cls
  cls = class(name) {
    __new = function(...)
      if immutable then
        -- Wrap values in a sub-table so __newindex catches every
        -- assignment to the instance (Lua __newindex only fires
        -- on keys not already present; mutating an instance field
        -- with direct keys would bypass it).
        return {_values = build_values(...)}
      end
      return build_values(...)
    end,

    __init = function(self) end,

    __index = function(self, k)
      if immutable and field_index[k] then
        return self._values[k]
      end
      return cls.__defaultindex(self, k)
    end,

    __newindex = immutable and function(self, k)
      -- Mirror Python's frozen dataclass: assigning to a field of a frozen
      -- instance raises AttributeError; subscript assignment is a TypeError.
      if type(k) == 'number' then
        error(exceptions.TypeError(
          "'" .. name .. "' object does not support item assignment"))
      end
      error(exceptions.AttributeError(
        "cannot assign to field '" .. tostring(k) .. "' of frozen '"
          .. name .. "'"))
    end or nil,

    __eq = function(self, other)
      for i = 1, n_fields do
        if self[field_names[i]] ~= other[field_names[i]] then
          return false
        end
      end
      return true
    end,

    __hash = function(self, result)
      local hash = require 'llx.hash'
      result = hash.hash_string(name, result)
      for i = 1, n_fields do
        result = hash.hash_value(self[field_names[i]], result)
      end
      return result
    end,

    __tostring = function(self)
      local parts = {}
      for i = 1, n_fields do
        parts[i] =
          field_names[i] .. '=' .. tostring(self[field_names[i]])
      end
      return name .. '(' .. table.concat(parts, ', ') .. ')'
    end,

    --- Returns the declared field names in order.
    fields = function(self)
      local copy = {}
      for i = 1, n_fields do copy[i] = field_names[i] end
      return copy
    end,

    --- Returns a plain Lua map of name -> value.
    as_table = function(self)
      local t = {}
      for i = 1, n_fields do
        t[field_names[i]] = self[field_names[i]]
      end
      return t
    end,

    --- Returns a new instance with the given fields overridden.
    -- Other fields keep their current values. Useful pattern for
    -- "update one field" on immutable dataclasses.
    replace = function(self, overrides)
      local kwargs = {}
      for i = 1, n_fields do
        local fname = field_names[i]
        kwargs[fname] = self[fname]
      end
      if overrides then
        for k, v in pairs(overrides) do
          if field_index[k] == nil then
            error(string.format(
              '%s.replace: unknown field "%s"', name, k), 2)
          end
          kwargs[k] = v
        end
      end
      return cls(kwargs)
    end,
  }

  return cls
end

return _M

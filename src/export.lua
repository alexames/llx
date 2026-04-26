-- Copyright 2026 Alexander Ames <Alexander.Ames@gmail.com>
--
-- Configurable variable declarations with schema-backed validation, change
-- observers, serialization, and per-field UI hints.
--
-- A Config groups named fields. Each field is declared by a schema table
-- (anything accepted by llx.Schema) that may carry extra keys the schema
-- layer ignores -- notably `default` and `ui_hint`.
--
--   local config = export.Config 'Audio' {
--     volume = { type = Number, default = 0.8,
--                minimum = 0, maximum = 1, ui_hint = 'slider' },
--     muted  = { type = Boolean, default = false, ui_hint = 'checkbox' },
--   }
--
--   config.volume = 0.4              -- validated against the schema
--   local v = config.volume          -- live read
--   config:on_change('volume', f)    -- reactive hookup
--   for name, schema in config:fields() do ... end
--   config:serialize() / :deserialize(data) / :reset()

local environment = require 'llx.environment'
local schema_module = require 'llx.schema'

local _ENV, _M = environment.create_module_environment()

local Schema = schema_module.Schema
local matches_schema = schema_module.matches_schema

local function ensure_schema(value, name)
  assert(type(value) == 'table',
         string.format("field '%s' must be a table (schema)", name))
  assert(value.type ~= nil,
         string.format("field '%s' schema is missing required 'type'", name))
  -- Schema() decorates the table with __isinstance and a metatable; calling it
  -- on a value that already has __isinstance would clobber any caller-attached
  -- metatable, so make this idempotent.
  if value.__isinstance == nil then
    return Schema(value)
  end
  return value
end

local function build_field(name, schema)
  local default = schema.default
  if default ~= nil then
    -- Surface bad declarations at Config-creation time rather than later.
    matches_schema(schema, default)
  end
  return {
    name = name,
    schema = schema,
    value = default,
  }
end

local function notify(
    observers_by_field, global_observers, name, value, previous)
  local list = observers_by_field[name]
  if list then
    for _, callback in ipairs(list) do
      callback(value, previous, name)
    end
  end
  for _, callback in ipairs(global_observers) do
    callback(name, value, previous)
  end
end

local function make_config(title, fields_by_name)
  local observers_by_field = {}
  local global_observers = {}

  local proxy = {}
  local methods = {}

  --- Iterates fields. Yields (name, schema). The schema is the same table the
  -- module declared (or its Schema() wrapping); read ui_hint, default, type,
  -- and any constraints directly off it. For the live value, read proxy[name].
  function methods:fields()
    local key
    return function()
      local field
      key, field = next(fields_by_name, key)
      if field then return field.name, field.schema end
    end
  end

  --- Returns the schema table for a field, or nil if not declared.
  function methods:get_schema(name)
    local field = fields_by_name[name]
    if field then return field.schema end
  end

  --- Restores every field to its declared default and fires observers for
  -- each field that actually changed.
  function methods:reset()
    for _, field in pairs(fields_by_name) do
      local previous = field.value
      if previous ~= field.schema.default then
        field.value = field.schema.default
        notify(observers_by_field, global_observers,
               field.name, field.value, previous)
      end
    end
  end

  --- Registers an observer.
  --   cfg:on_change('volume', function(new, previous, name) end)
  --   cfg:on_change(function(name, new, previous) end)  -- global
  function methods:on_change(name_or_callback, callback)
    if type(name_or_callback) == 'function' then
      table.insert(global_observers, name_or_callback)
      return
    end
    local name = name_or_callback
    assert(fields_by_name[name],
           string.format("on_change: unknown field '%s'", name))
    local list = observers_by_field[name]
    if not list then
      list = {}
      observers_by_field[name] = list
    end
    table.insert(list, callback)
  end

  --- Returns a plain { name = value, ... } table suitable for persistence.
  function methods:serialize()
    local result = {}
    for name, field in pairs(fields_by_name) do
      result[name] = field.value
    end
    return result
  end

  --- Loads values from a plain table. Unknown keys are ignored. Each value is
  -- validated against its field schema; on mismatch the error propagates and
  -- partially-applied state is left in place.
  function methods:deserialize(data)
    assert(type(data) == 'table', 'deserialize expects a table')
    for name, value in pairs(data) do
      if fields_by_name[name] then
        proxy[name] = value
      end
    end
  end

  --- Returns the title supplied at declaration.
  function methods:title()
    return title
  end

  local proxy_metatable = {
    __index = function(_, key)
      local method = methods[key]
      if method then return method end
      local field = fields_by_name[key]
      if field then return field.value end
      error(string.format("Config '%s' has no field or method '%s'",
                          title, key), 2)
    end,

    __newindex = function(_, key, value)
      local field = fields_by_name[key]
      if not field then
        error(string.format("Config '%s' has no field '%s'", title, key), 2)
      end
      matches_schema(field.schema, value)
      local previous = field.value
      if previous == value then return end
      field.value = value
      notify(observers_by_field, global_observers, key, value, previous)
    end,

    __pairs = function()
      local key
      return function()
        local field
        key, field = next(fields_by_name, key)
        if field then return field.name, field.value end
      end
    end,

    __tostring = function() return 'Config<' .. title .. '>' end,
  }

  return setmetatable(proxy, proxy_metatable)
end

--- Declares a Config.
--
--   Config 'Title' { name = schema_table, ... }
--
-- Each value must be a Schema-compatible table. Extra keys (`default`,
-- `ui_hint`, `description`, etc.) are allowed and exposed via :get_schema()
-- and :fields() for UI consumers.
function Config(title)
  assert(type(title) == 'string', 'Config title must be a string')
  return function(declarations)
    assert(type(declarations) == 'table', 'Config body must be a table')

    local fields_by_name = {}
    for name, value in pairs(declarations) do
      assert(type(name) == 'string',
             string.format(
                 "Config '%s' field names must be strings", title))
      local schema = ensure_schema(value, name)
      fields_by_name[name] = build_field(name, schema)
    end

    return make_config(title, fields_by_name)
  end
end

return _M

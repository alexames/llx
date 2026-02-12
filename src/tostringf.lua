-- Copyright 2025 Alexander Ames <Alexander.Ames@gmail.com>

local core = require 'llx.core'
local table_module = require 'llx.types.table'
local class_module = require 'llx.class'
local environment = require 'llx.environment'
local set_module = require 'llx.types.set'
local enum_module = require 'llx.enum'

local _ENV, _M = environment.create_module_environment()

local getmetafield = core.getmetafield
local class = class_module.class
local Table = table_module.Table
local Set = set_module.Set
local enum = enum_module.enum

local KEYWORDS <const> = Set{
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
  'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
  'true', 'until', 'while'
}

local NAME_PATTERN = '^%a%w*$'

function tostringf(value, style)
  local formatter = StringFormatter(style)
  formatter:format(value)
  return formatter:concat()
end

function default_formatter(self, value)
  self:insert(value)
end

local function table_is_list(t)
  local count = 0
  for k, _ in pairs(t) do
    if type(k) ~= 'number' then return false end
    count = count + 1
  end
  return count == #t
end

StringFormatter = class 'StringFormatter' {
  __init = function(self, style, buffer, indentation_level)
    self._style = style
    self._buffer = buffer or Table{}
    self._indentation_level = indentation_level or 0
  end,

  clone = function(self, style)
    return StringFormatter(style, self._buffer, self._indentation_level)
  end,

  insert = function(self, value)
    self._buffer:insert(value)
  end,

  concat = function(self)
    return self._buffer:concat()
  end,

  format = function(self, value, style)
    local __tostringf = getmetafield(value, '__tostringf')
    if __tostringf then
      __tostringf(value, self)
    else
      self[type(value)](self, value, style)
    end
  end,

  ['nil'] = function(self) self:insert('nil') end,
  boolean = function(self, value) self:insert(tostring(value)) end,
  number = default_formatter,
  string = function(self, value)
    local begin_quote
    local end_quote
    if not value:match("'") then
      begin_quote, end_quote = "'", "'"
    elseif not value:match('"') then
      begin_quote, end_quote = '"', '"'
    else
      local count = 0
      repeat
        end_quote = ']' .. string.rep('=', count) .. ']'
        count = count + 1
      until not value:match(end_quote)
      begin_quote = '[' .. string.rep('=', count) .. '['
    end
    self:insert(begin_quote)
    self:insert(value)
    self:insert(end_quote)
  end,
  ['function'] = default_formatter,
  thread = default_formatter,
  userdata = default_formatter,

  new_line = function(self)
    self._new_line_pending = true
  end,

  actually_add_new_line = function(self)
    self:insert('\n')
    self:insert(self._style.indent:rep(self._indentation_level))
    self._new_line_pending = false
  end,

  table = function(self, value, style)
    self:table_begin()
    local value_formatter = style and self:clone(style) or self
    if table_is_list(value) then
      for i, v in ipairs(value) do
        local final_field = i == #value
        if self._new_line_pending then
          self:actually_add_new_line()
        end
        value_formatter:format(v)
        self:table_field_delimiter(final_field)
      end
    else
      for k, v in pairs(value) do
        local final_field = next(value, k) == nil
        self:table_field(k, v, final_field, value_formatter)
      end
    end
    self:table_end()
  end,

  table_cons = function(self, name)
    if type(name) == 'table' then
      self:module_class(table.unpack(name))
    else
      self:insert(name)
    end
    return self
  end,

  module_class = function(self, module_name, class_name)
    if self._style.type_verbosity == TypeVerbosity.ModuleTypeField then
      self:insert(module_name)
      self:insert('.')
    end
    self:insert(class_name)
  end,

  module_class_field = function(self, module_name, class_name, field_name)
    if self._style.type_verbosity == TypeVerbosity.ModuleTypeField then
      self:insert(module_name)
      self:insert('.')
    end
    if self._style.type_verbosity == TypeVerbosity.TypeField then
      self:insert(class_name)
      self:insert('.')
    end
    self:insert(field_name)
  end,

  __call = function(self, args)
    self:table_fields(args)
  end,

  table_key = function(self, key)
    local key_type = type(key)
    local is_name = key_type == 'string' and key:match(NAME_PATTERN) and not rawget(KEYWORDS, '_values')[key]
    if is_name then
      self:insert(key)
    else
      self:insert('[')
      self:format(key)
      self:insert(']')
    end
  end,

  table_begin = function(self)
    self:insert('{')
    if self._style.multiline_tables then
      self._indentation_level = self._indentation_level + 1
      self:new_line()
    end
  end,

  table_field_delimiter = function(self, final_field)
    if not final_field or self._style.include_final_delimiter then
      self:insert(self._style.delimiter)
    end
    if self._style.multiline_tables then
      self:new_line()
    end
  end,

  table_field = function(self, key, value, final_field, value_formatter, element_style)
    if self._new_line_pending then
      self:actually_add_new_line()
    end
    self:table_key(key)
    if self._style.space_before_assignment then
      self:insert(' ')
    end
    self:insert('=')
    if self._style.space_after_assignment then
      self:insert(' ')
    end
    local value_formatter = value_formatter or self
    value_formatter:format(value, element_style)
    self:table_field_delimiter(final_field)
  end,

  table_fields = function(self, fields)
    self:table_begin()
    for i, field in ipairs(fields) do
      local key, value, value_style = table.unpack(field)
      local value_formatter = value_style and self:clone(value_style) or self
      local final_field = i == #fields
      self:table_field(key, value, final_field, value_formatter, field.element_style)
    end
    self:table_end()
  end,

  table_end = function(self)
    if self._style.multiline_tables then
      self._indentation_level = self._indentation_level - 1
    end
    if self._new_line_pending then
      self:actually_add_new_line()
    end
    self:insert('}')
  end,
}

TypeVerbosity = enum 'TypeVerbosity' {
  'Field',
  'TypeField',
  'ModuleTypeField',
}

styles = {
  minimal = {
    type_verbosity = TypeVerbosity.Field,
    indent = '',
    delimiter = ',',
    include_final_delimiter = false,
    multiline_tables = false,
    space_before_assignment = false,
    space_after_assignment = false,
  },
  abbrev = {
    type_verbosity = TypeVerbosity.TypeField,
    indent = '',
    delimiter = ', ',
    include_final_delimiter = false,
    multiline_tables = false,
    space_before_assignment = false,
    space_after_assignment = false,
  },
  struct = {
    type_verbosity = TypeVerbosity.ModuleTypeField,
    indent = '  ',
    delimiter = ',',
    include_final_delimiter = true,
    multiline_tables = true,
    space_before_assignment = true,
    space_after_assignment = true,
  },
}

return _M

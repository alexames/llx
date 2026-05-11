-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx.class' . class
local environment = require 'llx.environment'
local Exception = require 'llx.exceptions.exception' . Exception

local _ENV, _M = environment.create_module_environment()

SchemaException = class 'SchemaException' : extends(Exception) {
  __init = function(self, path, failure_reason, level)
    local path_str = #path > 0 and ('`'..table.concat(path, '.')..'`') or 'root'
    local what = string.format('error at %s: %s',
                               path_str, failure_reason)
    Exception.__init(self, what, (level or 1) + 1)
    self.path = path
  end,

  __tostring = Exception.__tostring, -- Fix this.
}

SchemaFieldTypeMismatchException =
    class 'SchemaFieldTypeMismatchException' : extends(SchemaException) {
  __init = function(self, path, expected_type, actual_type,
                    actual_value, level)
    local failure_reason
    if actual_value ~= nil then
      local value_repr = tostring(actual_value)
      if #value_repr > 50 then
        value_repr = value_repr:sub(1, 47) .. '...'
      end
      failure_reason = string.format(
          '%s expected, got %s (%s)',
          expected_type.__name, actual_type.__name, value_repr)
    else
      failure_reason = string.format(
          '%s expected, got %s',
          expected_type.__name, actual_type.__name)
    end
    SchemaException.__init(self, path, failure_reason, (level or 1) + 1)
    self.actual_value = actual_value
    self.expected_type = expected_type
    self.actual_type = actual_type
  end,

  __tostring = SchemaException.__tostring, -- Fix this.
}

SchemaConstraintFailureException =
    class 'SchemaConstraintFailureException' : extends(SchemaException) {
  __init = function(self, path, failure_reason, level)
    SchemaException.__init(self, path, failure_reason, (level or 1) + 1)
  end,

  __tostring = SchemaException.__tostring, -- Fix this.
}

SchemaMissingFieldException =
    class 'SchemaMissingFieldException' : extends(SchemaException) {
  __init = function(self, path, field_key, level)
    local failure_reason = string.format(
        'missing required field %s', field_key)
    SchemaException.__init(self, path, failure_reason, (level or 1) + 1)
  end,

  __tostring = SchemaException.__tostring, -- Fix this.
}

return _M

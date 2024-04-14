-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx/class' . class
local environment = require 'llx/environment'
local Exception = require 'llx/exceptions/exception' . Exception

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
  __init = function(self, path, expected_type, actual_type, level)
    local failure_reason = string.format(
        '%s expected, got %s', expected_type.__name, actual_type.__name)
    SchemaException.__init(self, path, failure_reason, (level or 1) + 1)
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

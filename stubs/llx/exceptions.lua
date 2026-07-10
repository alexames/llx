---@meta

-- ---------------------------------------------------------------------------
-- Exception hierarchy. Every class here can be raised via Lua's
-- error() and caught by llx.flow_control's try/catch on the matching
-- class, a type matcher, or the class name as a string.
-- ---------------------------------------------------------------------------

---@class llx.exceptions
---@field Exception fun(what: string, level?: integer): llx.Exception
---@field ExceptionGroup fun(exception_list: llx.Exception[], level?: integer): llx.ExceptionGroup
---@field IndexError fun(what: string, level?: integer): llx.IndexError
---@field InvalidArgumentException fun(argument_index: integer|string, failure_reason: string, level?: integer): llx.InvalidArgumentException
---@field InvalidArgumentTypeException fun(argument_index: integer|string, expected_type: any, actual_type: any, level?: integer): llx.InvalidArgumentTypeException
---@field NotImplementedException fun(what: string, level?: integer): llx.NotImplementedException
---@field RuntimeError fun(what: string, level?: integer): llx.RuntimeError
---@field SchemaException fun(path: any[], failure_reason: string, level?: integer): llx.SchemaException
---@field SchemaFieldTypeMismatchException fun(path: any[], expected_type: any, actual_type: any, level?: integer): llx.SchemaFieldTypeMismatchException
---@field SchemaConstraintFailureException fun(path: any[], failure_reason: string, level?: integer): llx.SchemaConstraintFailureException
---@field SchemaMissingFieldException fun(path: any[], field_key: any, level?: integer): llx.SchemaMissingFieldException
---@field TypeError fun(what: string, level?: integer): llx.TypeError
---@field ValueException fun(what: string, level?: integer): llx.ValueException

-- Base class. `what` holds the human-readable message; `traceback`
-- holds a stack trace captured at construction time.
---@class llx.Exception
---@field what string
---@field traceback string
---@field __name string
local Exception = {}

--- Returns the short form: "ClassName: what" without a traceback.
---@return string
function Exception:message() end

---@class llx.ExceptionGroup : llx.Exception
---@field exception_list llx.Exception[]

---@class llx.IndexError : llx.Exception

---@class llx.InvalidArgumentException : llx.Exception

---@class llx.InvalidArgumentTypeException : llx.InvalidArgumentException

---@class llx.NotImplementedException : llx.Exception

---@class llx.RuntimeError : llx.Exception

-- Schema validation errors. `path` is the dotted location in the
-- value where the failure occurred (empty for the root).
---@class llx.SchemaException : llx.Exception
---@field path any[]

---@class llx.SchemaFieldTypeMismatchException : llx.SchemaException

---@class llx.SchemaConstraintFailureException : llx.SchemaException

---@class llx.SchemaMissingFieldException : llx.SchemaException

---@class llx.TypeError : llx.Exception

---@class llx.ValueException : llx.Exception

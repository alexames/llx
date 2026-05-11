---@meta

---@class llx.dataclass.field
---@field name string
---@field type? any
---@field default? any

---@class llx.dataclass.opts
---@field immutable? boolean Lock fields after construction

---@class llx.dataclass
local dataclass = {}

---@param name string
---@param fields llx.dataclass.field[]
---@param opts? llx.dataclass.opts
---@return llx.DataclassClass
function dataclass.dataclass(name, fields, opts) end

-- Base type that all generated dataclasses extend at the LSP level.
-- User code declares concrete instances with `---@class MyClass : llx.DataclassClass`.
---@class llx.DataclassClass
local DataclassClass = {}

---@return string[]
function DataclassClass:fields() end

---@return table<string, any>
function DataclassClass:as_table() end

---@param overrides table<string, any>
---@return llx.DataclassClass
function DataclassClass:replace(overrides) end

return dataclass

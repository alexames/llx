---@meta

---@class llx.contextlib
local contextlib = {}

---@generic T
---@param resource T
---@param fn fun(resource: T): any
---@return any ...
function contextlib.with(resource, fn) end

---@generic T
---@param resource T
---@return T
function contextlib.closing(resource) end

return contextlib

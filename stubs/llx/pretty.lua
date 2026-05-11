---@meta

---@class llx.pretty.opts
---@field indent? string Per-level indentation (default '  ')
---@field width? integer Target line width before breaking (default 80)
---@field max_depth? integer Cap nesting depth; deeper renders as {...}

---@class llx.pretty
local pretty = {}

---@param value any
---@param opts? llx.pretty.opts
---@return string
function pretty.format(value, opts) end

---@param value any
---@param opts? llx.pretty.opts
function pretty.pprint(value, opts) end

return pretty

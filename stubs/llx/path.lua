---@meta

---@class llx.path
local path = {}

---@param p string
---@return boolean
function path.is_absolute(p) end

---@param ... string
---@return string
function path.join(...) end

---@param p string
---@return string dirname
---@return string basename
function path.split(p) end

---@param p string
---@return string
function path.dirname(p) end

---@param p string
---@return string
function path.basename(p) end

---@param p string
---@return string stem_with_dirs
---@return string suffix
function path.splitext(p) end

---@param p string
---@return string
function path.normalize(p) end

---@param str string|llx.Path
---@return llx.Path
function path.Path(str) end

---@class llx.Path
---@operator div(string|llx.Path): llx.Path
local Path = {}

---@return llx.Path
function Path:parent() end
---@return string
function Path:name() end
---@return string
function Path:stem() end
---@return string
function Path:suffix() end
---@return string[]
function Path:suffixes() end
---@return string[]
function Path:parts() end
---@return boolean
function Path:is_absolute() end
---@param ... string
---@return llx.Path
function Path:join(...) end
---@param new_name string
---@return llx.Path
function Path:with_name(new_name) end
---@param new_suffix string
---@return llx.Path
function Path:with_suffix(new_suffix) end
---@return llx.Path
function Path:normalize() end
---@return boolean
function Path:exists() end
---@return string
function Path:read_text() end
---@return string
function Path:read_bytes() end
---@param content string
---@return llx.Path
function Path:write_text(content) end
---@param content string
---@return llx.Path
function Path:write_bytes(content) end

return path

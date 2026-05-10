---@meta

---@class llx.bisect
local bisect = {}

---@param a any[] # sorted sequence (1-indexed)
---@param x any
---@param lo? integer
---@param hi? integer
---@param key? fun(value: any): any
---@return integer
function bisect.bisect_left(a, x, lo, hi, key) end

---@param a any[]
---@param x any
---@param lo? integer
---@param hi? integer
---@param key? fun(value: any): any
---@return integer
function bisect.bisect_right(a, x, lo, hi, key) end

---@param a any[]
---@param x any
---@param lo? integer
---@param hi? integer
---@param key? fun(value: any): any
---@return integer
function bisect.bisect(a, x, lo, hi, key) end

---@param a any[]
---@param x any
---@param lo? integer
---@param hi? integer
---@param key? fun(value: any): any
---@return integer # the index at which x was inserted
function bisect.insort_left(a, x, lo, hi, key) end

---@param a any[]
---@param x any
---@param lo? integer
---@param hi? integer
---@param key? fun(value: any): any
---@return integer
function bisect.insort_right(a, x, lo, hi, key) end

---@param a any[]
---@param x any
---@param lo? integer
---@param hi? integer
---@param key? fun(value: any): any
---@return integer
function bisect.insort(a, x, lo, hi, key) end

return bisect

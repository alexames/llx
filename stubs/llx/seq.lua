---@meta

-- ---------------------------------------------------------------------------
-- Seq: chainable iterator wrapper for functional pipelines.
-- ---------------------------------------------------------------------------

---@class llx.Seq
---@overload fun(source: fun()|table): llx.Seq
local Seq = {}

-- Lazy transformations
---@param fn fun(value: any): any
---@return llx.Seq
function Seq:map(fn) end
---@param predicate fun(value: any): boolean
---@return llx.Seq
function Seq:filter(predicate) end
---@param predicate fun(value: any): boolean
---@return llx.Seq
function Seq:reject(predicate) end
---@param n integer
---@return llx.Seq
function Seq:take(n) end
---@param n integer
---@return llx.Seq
function Seq:drop(n) end
---@param predicate fun(value: any): boolean
---@return llx.Seq
function Seq:take_while(predicate) end
---@param predicate fun(value: any): boolean
---@return llx.Seq
function Seq:drop_while(predicate) end
---@param fn fun(value: any): fun()|table
---@return llx.Seq
function Seq:flat_map(fn) end
---@param key_fn? fun(value: any): any
---@return llx.Seq
function Seq:distinct(key_fn) end
---@return llx.Seq
function Seq:enumerate() end
---@param fn fun(value: any)
---@return llx.Seq
function Seq:tap(fn) end

-- Terminators
---@return llx.List
function Seq:collect() end
---@return llx.List
function Seq:to_list() end
---@param fn fun(value: any)
function Seq:for_each(fn) end
---@param fn fun(acc: any, value: any): any
---@param init? any
---@return any
function Seq:reduce(fn, init) end
---@return integer
function Seq:count() end
---@return any?
function Seq:first() end
---@return any?
function Seq:last() end
---@param predicate? fun(value: any): boolean
---@return boolean
function Seq:any(predicate) end
---@param predicate fun(value: any): boolean
---@return boolean
function Seq:all(predicate) end
---@param predicate fun(value: any): boolean
---@return boolean
function Seq:none(predicate) end
---@param predicate fun(value: any): boolean
---@return any?
function Seq:find(predicate) end
---@return number
function Seq:sum() end
---@return number
function Seq:product() end
---@return any?
function Seq:min() end
---@return any?
function Seq:max() end

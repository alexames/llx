---@meta

-- ---------------------------------------------------------------------------
-- List
--
-- Sequence-like collection. Inherits Table operations; adds slicing,
-- functional methods, and concatenation operators. Comparison and
-- hashing are by value.
-- ---------------------------------------------------------------------------

---@class llx.List
---@operator len: integer
---@operator concat(llx.List): llx.List
---@operator mul(integer): llx.List
---@operator shl(integer): llx.List
---@operator shr(integer): llx.List
---@overload fun(iterable?: table|fun()): llx.List
local List = {}

---@param other table
function List:extend(other) end
---@param value any
---@return boolean
function List:contains(value) end
---@param start? integer
---@param finish? integer
---@param step? integer
---@return llx.List
function List:sub(start, finish, step) end
---@return llx.List
function List:reverse() end
---@param func fun(value: any, index: integer): any
---@return llx.List
function List:map(func) end
---@param predicate fun(value: any, index: integer): boolean
---@return llx.List
function List:filter(predicate) end
---@param func fun(acc: any, value: any, index: integer): any
---@param initial? any
---@return any
function List:reduce(func, initial) end
---@param predicate fun(value: any, index: integer): boolean
---@return any?
function List:find(predicate) end
---@param predicate fun(value: any, index: integer): boolean
---@return integer?
function List:find_index(predicate) end
---@param comparator? fun(a: any, b: any): boolean
---@param in_place? boolean
---@return llx.List
function List:sort(comparator, in_place) end
---@param key_func fun(value: any, index: integer): any
---@return table<any, llx.List>, llx.List
function List:group_by(key_func) end
---@param other table
---@return llx.List
function List:zip(other) end
---@return llx.List
function List:flatten() end
---@param key_func? fun(value: any, index: integer): any
---@return llx.List
function List:distinct(key_func) end
---@param key_func? fun(value: any, index: integer): any
---@return llx.List
function List:unique(key_func) end
---@param predicate fun(value: any, index: integer): boolean
---@return boolean
function List:any(predicate) end
---@param predicate fun(value: any, index: integer): boolean
---@return boolean
function List:all(predicate) end
---@param predicate fun(value: any, index: integer): boolean
---@return boolean
function List:none(predicate) end
---@param n integer
---@return llx.List
function List:take(n) end
---@param n integer
---@return llx.List
function List:drop(n) end
---@param predicate fun(value: any, index: integer): boolean
---@return llx.List, llx.List
function List:partition(predicate) end
---@param n integer
---@return llx.List
function List:chunk(n) end
---@return number
function List:sum() end
---@return number
function List:product() end
---@param comparator? fun(a: any, b: any): boolean
---@return any
function List:min(comparator) end
---@param comparator? fun(a: any, b: any): boolean
---@return any
function List:max(comparator) end
---@return any
function List:first() end
---@return any
function List:last() end
---@return boolean
function List:is_empty() end
-- Inherited from Table
---@param pos_or_value any
---@param value? any
function List:insert(pos_or_value, value) end
---@param pos? integer
---@return any
function List:remove(pos) end

-- ---------------------------------------------------------------------------
-- Set
--
-- Unordered collection of unique values. Set operations are also
-- exposed as bitwise operators: `|` union, `-` difference,
-- `&` intersection, `~` symmetric_difference.
-- ---------------------------------------------------------------------------

---@class llx.Set
---@operator len: integer
---@operator bor(llx.Set): llx.Set
---@operator sub(llx.Set): llx.Set
---@operator band(llx.Set): llx.Set
---@operator bxor(llx.Set): llx.Set
---@overload fun(values?: table): llx.Set
local Set = {}

---@return llx.Set
function Set:copy() end
---@param key any
function Set:insert(key) end
---@param key any
function Set:remove(key) end
---@param other llx.Set
---@return llx.Set
function Set:union(other) end
---@param other llx.Set
---@return llx.Set
function Set:difference(other) end
---@param other llx.Set
---@return llx.Set
function Set:intersection(other) end
---@param other llx.Set
---@return llx.Set
function Set:symmetric_difference(other) end
---@param other llx.Set
---@return boolean
function Set:is_subset(other) end
---@param other llx.Set
---@return boolean
function Set:is_superset(other) end
---@param other llx.Set
---@return boolean
function Set:is_disjoint(other) end
---@return integer
function Set:len() end
---@param key any
---@return boolean
function Set:contains(key) end
---@param key any
---@return boolean?
function Set:get(key) end
---@param key any
---@param value any
function Set:set(key, value) end
---@param other llx.Set
function Set:update(other) end
function Set:clear() end
---@param f fun(key: any): any
---@return llx.Set
function Set:map(f) end
---@param pred fun(key: any): boolean
---@return llx.Set
function Set:filter(pred) end
---@return llx.List
function Set:tolist() end

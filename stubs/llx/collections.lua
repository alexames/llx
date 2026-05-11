---@meta

-- ---------------------------------------------------------------------------
-- Deque
-- ---------------------------------------------------------------------------

---@class llx.Deque
---@operator len: integer
---@overload fun(iterable?: table|fun()): llx.Deque
local Deque = {}

---@param iterable? table|fun()
---@return llx.Deque
function Deque.new(iterable) end
---@param value any
---@return llx.Deque
function Deque:push_right(value) end
---@param value any
---@return llx.Deque
function Deque:push_left(value) end
---@param value any
---@return llx.Deque
function Deque:push(value) end
---@return any
function Deque:pop_right() end
---@return any
function Deque:pop_left() end
---@return any
function Deque:pop() end
---@return any?
function Deque:peek_right() end
---@return any?
function Deque:peek_left() end
---@return boolean
function Deque:is_empty() end
---@return llx.Deque
function Deque:clear() end
---@param value any
---@return boolean
function Deque:contains(value) end
---@param index integer
---@return any
function Deque:at(index) end

-- ---------------------------------------------------------------------------
-- Counter
-- ---------------------------------------------------------------------------

---@class llx.Counter
---@operator len: integer
---@operator add(llx.Counter): llx.Counter
---@operator sub(llx.Counter): llx.Counter
---@overload fun(source?: table|fun()): llx.Counter
local Counter = {}

---@param key any
---@return integer
function Counter:get(key) end
---@param key any
---@param n? integer
---@return llx.Counter
function Counter:increment(key, n) end
---@param key any
---@param n? integer
---@return llx.Counter
function Counter:decrement(key, n) end
---@param key any
---@param value integer
---@return llx.Counter
function Counter:set(key, value) end
---@param key any
---@return llx.Counter
function Counter:delete(key) end
---@param key any
---@return boolean
function Counter:contains(key) end
---@return integer
function Counter:total() end
---@param n? integer
---@return table[] # array of {key, count} pairs sorted by descending count
function Counter:most_common(n) end
---@return fun(): integer?, any
function Counter:elements() end
---@return any[]
function Counter:keys() end

-- ---------------------------------------------------------------------------
-- OrderedDict
-- ---------------------------------------------------------------------------

---@class llx.OrderedDict
---@operator len: integer
---@overload fun(source?: table[]|fun()): llx.OrderedDict
local OrderedDict = {}

---@param key any
---@param value any
---@return llx.OrderedDict
function OrderedDict:set(key, value) end
---@param key any
---@return any?
function OrderedDict:get(key) end
---@param key any
---@return boolean # true iff a value was removed
function OrderedDict:delete(key) end
---@param key any
---@return boolean
function OrderedDict:contains(key) end
---@return any[]
function OrderedDict:keys() end
---@return any[]
function OrderedDict:values() end
---@return table[] # array of {key, value} pairs in insertion order
function OrderedDict:items() end
---@return llx.OrderedDict
function OrderedDict:clear() end
---@param key any
---@return llx.OrderedDict
function OrderedDict:move_to_end(key) end

-- ---------------------------------------------------------------------------
-- DefaultDict
-- ---------------------------------------------------------------------------

---@class llx.DefaultDict
---@operator len: integer
---@overload fun(factory: fun(key: any): any): llx.DefaultDict
local DefaultDict = {}

---@param key any
---@return any
function DefaultDict:get(key) end
---@param key any
---@return any?
function DefaultDict:peek(key) end
---@param key any
---@param value any
---@return llx.DefaultDict
function DefaultDict:set(key, value) end
---@param key any
---@return llx.DefaultDict
function DefaultDict:delete(key) end
---@param key any
---@return boolean
function DefaultDict:contains(key) end
---@return any[]
function DefaultDict:keys() end
---@return any[]
function DefaultDict:values() end
---@return llx.DefaultDict
function DefaultDict:clear() end

-- ---------------------------------------------------------------------------
-- Heap
-- ---------------------------------------------------------------------------

---@class llx.Heap
---@operator len: integer
---@overload fun(opts?: table): llx.Heap
local Heap = {}

---@param value any
---@return llx.Heap
function Heap:push(value) end
---@return any
function Heap:pop() end
---@return any?
function Heap:peek() end
---@return boolean
function Heap:is_empty() end
---@return llx.Heap
function Heap:clear() end
---@param n integer
---@return any[]
function Heap:top_n(n) end

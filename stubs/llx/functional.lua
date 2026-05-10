---@meta

---@class llx.functional
local functional = {}

-- Iterators
---@param a integer
---@param b? integer
---@param c? integer
---@return fun(): integer?, integer
function functional.range(a, b, c) end

---@param a integer
---@param b? integer
---@param c? integer
---@return fun(): integer?, integer
function functional.range_inclusive(a, b, c) end

---@param start? number
---@param step? number
---@return fun(): number
function functional.count(start, step) end

---@param sequence any
---@return fun(): integer?, any
function functional.cycle(sequence) end

---@param element any
---@param times? integer
---@return fun(): integer?, any
function functional.repeat_elem(element, times) end

-- Operations (function-first)
---@param lambda fun(...): any
---@param ... any
---@return llx.List
function functional.map(lambda, ...) end

---@param lambda fun(value: any): boolean
---@param sequence any
---@return fun(): integer?, any
function functional.filter(lambda, sequence) end

---@param predicate fun(value: any): boolean
---@param sequence any
---@return fun(): integer?, any
function functional.take_while(predicate, sequence) end

---@param predicate fun(value: any): boolean
---@param sequence any
---@return fun(): integer?, any
function functional.drop_while(predicate, sequence) end

---@param predicate fun(value: any): boolean
---@param sequence any
---@return any?
function functional.find(predicate, sequence) end

---@param predicate fun(value: any): boolean
---@param sequence any
---@return integer?
function functional.find_index(predicate, sequence) end

---@param predicate fun(value: any): boolean
---@param sequence any
---@return llx.List, llx.List
function functional.partition(predicate, sequence) end

-- Reductions (sequence-first)
---@param sequence any
---@param lambda fun(acc: any, value: any): any
---@param initial_value? any
---@return any
function functional.reduce(sequence, lambda, initial_value) end

---@param sequence any
---@param lambda fun(acc: any, value: any): any
---@param initial_value? any
---@return llx.List
function functional.accumulate(sequence, lambda, initial_value) end

---@param sequence any
---@return any
function functional.min(sequence) end

---@param sequence any
---@return any
function functional.max(sequence) end

---@param sequence any
---@return number
function functional.sum(sequence) end

---@param sequence any
---@return number
function functional.product(sequence) end

---@param predicate fun(value: any): boolean
---@param sequence any
---@return boolean
function functional.any(predicate, sequence) end

---@param predicate fun(value: any): boolean
---@param sequence any
---@return boolean
function functional.all(predicate, sequence) end

---@param predicate fun(value: any): boolean
---@param sequence any
---@return boolean
function functional.none(predicate, sequence) end

-- Combinators
---@param func function
---@param ... any
---@return function
function functional.partial(func, ...) end

---@param ... function
---@return function
function functional.compose(...) end

---@param ... function
---@return function
function functional.pipe(...) end

---@param func function
---@param n integer
---@return function
function functional.curry(func, n) end

---@param func function
---@return function
function functional.flip(func) end

---@param predicate function
---@return function
function functional.negate(predicate) end

---@param func function
---@return function
function functional.once(func) end

---@param value any
---@return fun(): any
function functional.constant(value) end

---@param func function
---@param key_func? function
---@return function
function functional.memoize(func, key_func) end

return functional

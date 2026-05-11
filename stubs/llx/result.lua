---@meta

-- ---------------------------------------------------------------------------
-- Result: Ok(value) or Err(err_value)
-- ---------------------------------------------------------------------------

---@class llx.Result
local Result = {}

---@param fn fun(...): any
---@param ... any
---@return llx.Result
function Result.try(fn, ...) end

---@return boolean
function Result:is_ok() end
---@return boolean
function Result:is_err() end
---@return any # raises on Err
function Result:unwrap() end
---@param default any
---@return any
function Result:unwrap_or(default) end
---@return any # raises on Ok
function Result:unwrap_err() end
---@param fn fun(value: any): any
---@return llx.Result
function Result:map(fn) end
---@param fn fun(err: any): any
---@return llx.Result
function Result:map_err(fn) end
---@param fn fun(value: any): llx.Result
---@return llx.Result
function Result:and_then(fn) end
---@param fn fun(err: any): llx.Result
---@return llx.Result
function Result:or_else(fn) end

-- ---------------------------------------------------------------------------
-- Option: Some(value) or None
-- ---------------------------------------------------------------------------

---@class llx.Option
local Option = {}

---@param value any
---@return llx.Option
function Option.from_nilable(value) end

---@return boolean
function Option:is_some() end
---@return boolean
function Option:is_none() end
---@return any # raises on None
function Option:unwrap() end
---@param default any
---@return any
function Option:unwrap_or(default) end
---@param fn fun(value: any): any
---@return llx.Option
function Option:map(fn) end
---@param fn fun(value: any): llx.Option
---@return llx.Option
function Option:and_then(fn) end
---@param fn fun(): llx.Option
---@return llx.Option
function Option:or_else(fn) end
---@param err_value any
---@return llx.Result
function Option:ok_or(err_value) end

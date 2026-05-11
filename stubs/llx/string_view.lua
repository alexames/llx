---@meta

-- ---------------------------------------------------------------------------
-- StringView
--
-- A non-copying view over a substring. Forwards most string-library
-- methods (sub, find, match, gmatch, gsub, lower, upper, byte, rep,
-- reverse) with indices adjusted to view-local space. The methods
-- `format`, `dump`, `pack`, `packsize`, `unpack`, and `char` are
-- deliberately not exposed.
-- ---------------------------------------------------------------------------

---@class llx.StringView
---@operator len: integer
---@overload fun(str: string, start?: integer, len?: integer): llx.StringView
local StringView = {}

---@return integer
function StringView:length() end

-- Forwarded string methods, with indices adjusted to view space.
---@param i? integer
---@param j? integer
---@return integer ...
function StringView:byte(i, j) end
---@param pattern string
---@param init? integer
---@param plain? boolean
---@return integer?, integer?
function StringView:find(pattern, init, plain) end
---@param pattern string
---@param init? integer
---@return string|nil ...
function StringView:match(pattern, init) end
---@param pattern string
---@return fun(): string|nil
function StringView:gmatch(pattern) end
---@param pattern string
---@param repl string|function|table
---@param max_n? integer
---@return string, integer
function StringView:gsub(pattern, repl, max_n) end
---@return string
function StringView:lower() end
---@return string
function StringView:upper() end
---@param n integer
---@param sep? string
---@return string
function StringView:rep(n, sep) end
---@return string
function StringView:reverse() end
---@param i integer
---@param j? integer
---@return string
function StringView:sub(i, j) end
---@return integer
function StringView:len() end

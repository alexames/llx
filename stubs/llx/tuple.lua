---@meta

-- ---------------------------------------------------------------------------
-- Tuple
--
-- Immutable, lexicographically-ordered, value-hashing sequence.
-- Attempting to write to a Tuple raises NotImplementedException.
-- ---------------------------------------------------------------------------

---@class llx.Tuple
---@operator len: integer
---@overload fun(items: table): llx.Tuple
local Tuple = {}

---@return ... unpacked elements
function Tuple:unpack() end

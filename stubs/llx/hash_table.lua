---@meta

-- ---------------------------------------------------------------------------
-- HashTable: value-equality keyed lookup table.
--
-- Hashes keys via llx.hash so any type with a __hash metamethod
-- (Tuple, Counter, Deque, OrderedDict, Set, List, namedtuple, etc.)
-- works as a key. Collisions are resolved by chaining on __eq.
-- ---------------------------------------------------------------------------

---@class llx.HashTable
---@overload fun(): llx.HashTable
local HashTable = {}

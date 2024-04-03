local Tuple = require 'llx/src/tuple' . Tuple
local hash = require 'llx/src/hash'

for i, v in ipairs(Tuple{1, '2', 3}) do
	print(i, v)
end
print(Tuple{1, 2, 3})
print(hash.hash(Tuple{1, '2', 3}))


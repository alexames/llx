-- examples/08_namedtuple_bisect.lua
-- Immutable namedtuple records and binary search via bisect.

local llx = require 'llx'
local namedtuple = llx.namedtuple
local bisect = llx.bisect

-- namedtuple: positional and named access on an immutable record.
local Point = namedtuple('Point', {'x', 'y'})
local p = Point(3, 4)
print(p.x, p.y)                              --> 3 4
print(p[1], p[2])                            --> 3 4
print(tostring(p))                           --> Point(x=3, y=4)
-- p.x = 99 would raise.

-- Equality and hashing are by value, so namedtuples work as
-- HashTable keys.
print(Point(3, 4) == Point(3, 4))            --> true
print(Point(3, 4) == Point(3, 5))            --> false

-- Field introspection.
local fields = p:fields()
for i, name in ipairs(fields) do print(i, name) end  --> 1 x, 2 y

-- bisect: binary search on a sorted sequence.
local sorted = {1, 3, 5, 7, 9, 11}

-- Find insertion point that keeps the sequence sorted.
print(bisect.bisect_left(sorted, 6))         --> 4 (between 5 and 7)

-- bisect_left vs bisect_right differ on existing elements.
local with_dups = {1, 2, 2, 2, 3}
print(bisect.bisect_left(with_dups, 2))      --> 2 (before duplicates)
print(bisect.bisect_right(with_dups, 2))     --> 5 (after duplicates)

-- insort_right keeps a sequence sorted across many insertions.
local stream = {}
local data = {5, 2, 8, 1, 9, 3, 7, 4, 6}
for _, v in ipairs(data) do bisect.insort_right(stream, v) end
print(table.concat(stream, ', '))            --> 1, 2, 3, 4, 5, 6, 7, 8, 9

-- bisect with a key function: binary search by attribute.
local people = {
  Point(10, 0), Point(20, 0), Point(30, 0), Point(40, 0),
}
local key = function(p) return p.x end
local i = bisect.bisect_left(people, Point(25, 0), nil, nil, key)
print(i)                                     --> 3 (insert between x=20 and x=30)

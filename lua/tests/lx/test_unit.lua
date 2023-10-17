
EXPECT_TRUE(true)
EXPECT_TRUE(1 == 1)
EXPECT_FALSE(false)
EXPECT_FALSE(1 ~= 1)

EXPECT_EQ(nil, nil)
EXPECT_EQ(true, true)
EXPECT_EQ(false, false)
EXPECT_EQ(1, 1)
EXPECT_EQ("hello, world", "hello, world")
EXPECT_EQ(next, next)
local t = {a=100, b="hello"}
EXPECT_EQ(t, t)

EXPECT_NE(1, 2)
EXPECT_NE(true, false)
EXPECT_NE(false, true)
EXPECT_NE("hello", "world")
EXPECT_NE(next, print)
EXPECT_NE({a=100, b="hello"}, {a=100})
EXPECT_NE({b="hello"}, {a=100, b="hello"})
EXPECT_NE({a=100, b="hello"}, {c=100, d="hello"})
EXPECT_NE({1, 2}, {1, 2, 3})
EXPECT_NE({1, 2, 3}, {2, 3})
EXPECT_NE({1, 2}, {2, 3})

EXPECT_THAT({1, 2, 3}, Listwise(Equals, {1, 2, 3}))
EXPECT_THAT({1, 2, 3}, Listwise(function(v) return Not(Equals(v)) end, {2, 4, 6}))
EXPECT_THAT({1, 2, 3}, Not(Listwise(Equals, {1, 2, 4})))
EXPECT_THAT({1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end, {1, 2, 3})))
EXPECT_THAT({1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end, {1, 2, 4})))

EXPECT_THAT({a=100, b="hello"}, Tablewise(Equals, {a=100, b="hello"}))
EXPECT_THAT({a=100, b="hello"}, Tablewise(function(v) return Not(Equals(v)) end, {a=1000, b="goodbye"}))
EXPECT_THAT({a=100, b="hello"}, Not(Tablewise(Equals, {a=100, b="hello", c="world"})))
EXPECT_THAT({a=100, b="hello", c="world"}, Not(Tablewise(Equals, {a=100, b="hello"})))

-- -- Test to ensure they fail when they get bad values
EXPECT_FALSE(pcall(EXPECT_TRUE, false))
EXPECT_FALSE(pcall(EXPECT_FALSE, true))

EXPECT_FALSE(pcall(EXPECT_EQ, nil, 1))
EXPECT_FALSE(pcall(EXPECT_EQ, true, false))
EXPECT_FALSE(pcall(EXPECT_EQ, nil, 1))
EXPECT_FALSE(pcall(EXPECT_EQ, false, true))
EXPECT_FALSE(pcall(EXPECT_EQ, 1, 2))
EXPECT_FALSE(pcall(EXPECT_EQ, "hello", "world"))
EXPECT_FALSE(pcall(EXPECT_EQ, next, print))
EXPECT_FALSE(pcall(EXPECT_EQ, {a=100, b="hello"}, {a=100}))
EXPECT_FALSE(pcall(EXPECT_EQ, {b="hello"}, {a=100, b="hello"}))
EXPECT_FALSE(pcall(EXPECT_EQ, {a=100, b="hello"}, {c=100, d="hello"}))
EXPECT_FALSE(pcall(EXPECT_EQ, {1, 2}, {1, 2, 3}))
EXPECT_FALSE(pcall(EXPECT_EQ, {1, 2, 3}, {2, 3}))
EXPECT_FALSE(pcall(EXPECT_EQ, {1, 2}, {2, 3}))

EXPECT_FALSE(pcall(EXPECT_NE, nil, nil))
EXPECT_FALSE(pcall(EXPECT_NE, true, true))
EXPECT_FALSE(pcall(EXPECT_NE, false, false))
EXPECT_FALSE(pcall(EXPECT_NE, 1, 1))
EXPECT_FALSE(pcall(EXPECT_NE, "hello, world", "hello, world"))
EXPECT_FALSE(pcall(EXPECT_NE, next, next))

EXPECT_FALSE(pcall(EXPECT_THAT, {1, 2, 3}, Not(Listwise(function(v) return Not(Equals(v)) end, {2, 4, 65}))))

EXPECT_FALSE(pcall(EXPECT_THAT, {7, 8, 9},
                         Listwise(function(v) return GreaterThan(v) end,
                                  {12, 2, 3})))

EXPECT_FALSE(pcall(EXPECT_THAT, {{1, 2, 3}, {4, 5, 6}, {7, 8, 9}},
                         Listwise(function(v) return Listwise(GreaterThanOrEqual, v) end,
                                  {{1, 2, 3}, {4, 5, 6}, {7, 8, 10}})))


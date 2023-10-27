require 'unit/matchers'

local fmt = 'expected %s\n  %s\nto %s\n  %s'
function EXPECT_THAT(actual, predicate, level, s)
  level = level or 2
  result, act, msg, nmsg, exp = predicate(actual, false)
  if not result then
    error(fmt:format(s or '', act, msg, exp), level)
  end
end

function EXPECT_TRUE(actual, level)
  level = level or 3
  EXPECT_THAT(actual, Equals(true), level)
end

function EXPECT_FALSE(actual)
  level = level or 3
  EXPECT_THAT(actual, Equals(false), level)
end

function EXPECT_EQ(actual, expected)
  level = level or 3
  EXPECT_THAT(actual, Equals(expected), level)
end

function EXPECT_NE(actual, expected)
  level = level or 3
  EXPECT_THAT(actual, Not(Equals(expected)), level)
end

return {
  EXPECT_THAT=EXPECT_THAT,
  EXPECT_TRUE=EXPECT_TRUE,
  EXPECT_FALSE=EXPECT_FALSE,
  EXPECT_EQ=EXPECT_EQ,
  EXPECT_NE=EXPECT_NE,
}

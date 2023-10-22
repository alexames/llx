require 'unit/matchers'

local fmt = 'expected %s\n  %s\nto %s\n  %s'
function EXPECT_THAT(actual, predicate, s)
  result, act, msg, nmsg, exp = predicate(actual, false)
  if not result then
    error(fmt:format(s or '', act, msg, exp))
  end
end

function EXPECT_TRUE(actual)
  EXPECT_THAT(actual, Equals(true))
end

function EXPECT_FALSE(actual)
  EXPECT_THAT(actual, Equals(false))
end

function EXPECT_EQ(actual, expected)
  EXPECT_THAT(actual, Equals(expected))
end

function EXPECT_NE(actual, expected)
  EXPECT_THAT(actual, Not(Equals(expected)))
end
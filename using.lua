
function using(newLocals)
  local callerEnv = getfenv(2)
  setfenv(2, setmetatable({}, {
    __index = function(unused, key)
      return newLocals[key] or callerEnv[key]
    end
  }))
end


-- enum1 = {
--   AAA = 1,
--   BBB = 2,
--   CCC = 3,
--   DDD = 4,
-- }
-- enum2 = {
--   EEE = 10,
--   FFF = 20,
--   GGG = 30,
--   HHH = 40,
-- }

-- function test()
--   using(enum1)
--   using(enum2)

--   print("AAA", AAA)
--   print("EEE", EEE)
-- end

-- test()
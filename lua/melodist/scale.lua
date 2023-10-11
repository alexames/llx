
require 'mode'
require 'pitch'
require 'util'
require 'chord'


class 'Scale' {
  __init = function(self, tonic, mode)
    if tonic == nil then
      error("tonic cannot be nil")
    elseif mode == nil then
      error("mode cannot be nil")
    end
    self.tonic = tonic
    self.mode = mode
  end

  function getPitches(self)
    -- return [self.tonic + pitchInterval
    --         for pitchInterval in self.mode.pitchIntervals.values]
  end

  function toPitch(self, scaleIndex)
    if scaleIndex == nil then
      -- return nil
    end
    return self.tonic + self.mode[scaleIndex]
  end

  function toPitches(self, scaleIndices)
    -- return [self.toPitch(scaleIndex) for scaleIndex in scaleIndices]
  end

  function toScaleIndex(self, pitch)
    if isinstance(pitch, int) then
      pitchIndex = pitch
    else
      pitchIndex = int(pitch)
    end

    pitchIndexOffset = pitchIndex - int(self.tonic)
    offsetModulus = pitchIndexOffset % int(self.mode.octaveInterval)
    offsetOctave = math.floor(pitchIndexOffset / int(self.mode.octaveInterval))
    -- try:
    --   scaleIndexModulus = [int(pitch - self.tonic)
    --                        for pitch in self.getPitches()].index(offsetModulus)
    --   return scaleIndexModulus + #self * offsetOctave
    -- except:
    --   return nil
  end


  function toScaleIndices(self, pitches)
    -- return [self.toScaleIndex(pitch) for pitch in pitches]
  end

  function relative(self, arg)
    -- scaleIndex=nil, mode=nil, direction=up
    if direction ~= up and direction ~= down then
      -- raise ValueError("must specify up or down")
    end

    if mode then
      scaleIndex = self.mode.relative(mode)
      if not scaleIndex then
        error("unrelated mode")
      end
      if direction == down then
        scaleIndex -= #self
      end
    elseif scaleIndex ~= nil then
      mode = self.mode:rotate(scaleIndex)
    end

    tonicScaleIndex = self.toScaleIndex(int(self.tonic)) + scaleIndex
    tonic = self:toPitch(tonicScaleIndex)

    return Scale{tonic=tonic, mode=mode}
  end


  function parallel(self, mode)
    return Scale{tonic=self.tonic, mode=mode}
  end


  function __eq(self, other)
    return self.tonic == other.tonic and self.mode == other.mode
  end


  function __len(self)
    return #self.mode
  end


  function __index(self, key)
    if isinstance(key, int) then
      return self.toPitch(key)
    elseif isinstance(key, range) or isinstance(key, slice) then
      start = key.start if key.start else 0
      stop = key.stop
      step = key.step if key.step else 1
      -- return [self[index] for index in range(start, stop, step)]
    else
      -- return [self.toPitch(index) for index in key]
    end
  end


  function contains(self, other)
    if isinstance(other, int) or isinstance(other, Pitch) then
      otherPitchIndices = [other]
    elseif isinstance(other, tuple) or isinstance(other, list) then
      otherPitchIndices = other
    elseif isinstance(other, Chord) or isinstance(other, Scale) then
      otherPitchIndices = other.getPitches()
    end

    function canonicalize(pitchIndices, octaveInterval)
      -- return [int(index) % int(octaveInterval) for index in pitchIndices]
    end

    octaveInterval = self.mode.octaveInterval
    otherPitchIndices = canonicalize(otherPitchIndices, octaveInterval)
    myPitchIndices = canonicalize(self.getPitches(), octaveInterval)
    -- return all(index in myPitchIndices
    --            for index in otherPitchIndices)
  end

  function __repr(self)
    return "Scale{tonic=%s, mode=%s}":format(self.tonic, self.mode)
  end
}


function findChord(scale, quality, nth=0, *, direction=up, scaleIndices=[0,2,4])
  numberFound = 0
  -- Search one octave at a time.
  local start = 0
  local finish = direction * #scale
  while true do
    for rootScaleIndex in range(start, finish, direction) do
      testQuality = Quality{pitches=scale[(i + rootScaleIndex for i in scaleIndices)]}

      if testQuality == quality then
        if numberFound == nth then
          return Chord{root=scale:toPitch(rootScaleIndex),
                       quality=quality}
        end
        numberFound = numberFound + 1
      end
    end
    start += direction * #scale
    finish += direction * #scale
    -- If after one full octave there have not been any matches,
    -- there won't be any matches going forward either. We should
    -- return nil. If there was at least one match though, we should
    -- keep searching until we find the nth match
    if numberFound == 0 then
      return nil
    end
  end


ScaleIndex = {
  tonic = 0,
  second = 1,
  third = 2,
  fourth = 3,
  fifth = 4,
  sixth = 5,
  seventh = 6,
  octave = 7,
}


-- if __name == "__main" then
--   import unittest
--   class 'ScaleTest'(unittest.TestCase)
--     function test_getPitches(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(scale.getPitches(),
--                        [Pitch.c4, Pitch.d4, Pitch.e4, Pitch.f4, Pitch.g4, Pitch.a5, Pitch.b5])


--     function test_toPitch(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(scale.toPitch(-8), Pitch.b3)
--       EXPECT_EQUAL(scale.toPitch(-7), Pitch.c3)
--       EXPECT_EQUAL(scale.toPitch(-6), Pitch.d3)
--       EXPECT_EQUAL(scale.toPitch(-5), Pitch.e3)
--       EXPECT_EQUAL(scale.toPitch(-4), Pitch.f3)
--       EXPECT_EQUAL(scale.toPitch(-3), Pitch.g3)
--       EXPECT_EQUAL(scale.toPitch(-2), Pitch.a4)
--       EXPECT_EQUAL(scale.toPitch(-1), Pitch.b4)
--       EXPECT_EQUAL(scale.toPitch(0), Pitch.c4)
--       EXPECT_EQUAL(scale.toPitch(1), Pitch.d4)
--       EXPECT_EQUAL(scale.toPitch(2), Pitch.e4)
--       EXPECT_EQUAL(scale.toPitch(3), Pitch.f4)
--       EXPECT_EQUAL(scale.toPitch(4), Pitch.g4)
--       EXPECT_EQUAL(scale.toPitch(5), Pitch.a5)
--       EXPECT_EQUAL(scale.toPitch(6), Pitch.b5)
--       EXPECT_EQUAL(scale.toPitch(7), Pitch.c5)
--       EXPECT_EQUAL(scale.toPitch(8), Pitch.d5)


--     function test_toPitches(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(scale.toPitches([-8, -7, -5, -3, -1, 0, 1, 3, 5, 7, 8]),
--                              [Pitch.b3,
--                               Pitch.c3,
--                               Pitch.e3,
--                               Pitch.g3,
--                               Pitch.b4,
--                               Pitch.c4,
--                               Pitch.d4,
--                               Pitch.f4,
--                               Pitch.a5,
--                               Pitch.c5,
--                               Pitch.d5])


--     function test_toScaleIndex(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(scale.toScaleIndex(Pitch.a4), -2)
--       EXPECT_EQUAL(scale.toScaleIndex(Pitch.c4), 0)
--       EXPECT_EQUAL(scale.toScaleIndex(Pitch.e4), 2)


--     function test_relative(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(scale.relative(mode=Mode.minor),
--                        Scale(tonic=Pitch.a5, mode=Mode.minor))
--       EXPECT_EQUAL(scale.relative(mode=Mode.minor, direction=down),
--                        Scale(tonic=Pitch.a4, mode=Mode.minor))


--     function test_parallel(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(scale.parallel(mode=Mode.minor),
--                        Scale(tonic=Pitch.c4, mode=Mode.minor))


--     function test_len(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(#scale, 7)


--     function test_getitem(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(scale[-8], Pitch.b3)
--       EXPECT_EQUAL(scale[-7], Pitch.c3)
--       EXPECT_EQUAL(scale[-6], Pitch.d3)
--       EXPECT_EQUAL(scale[-5], Pitch.e3)
--       EXPECT_EQUAL(scale[-4], Pitch.f3)
--       EXPECT_EQUAL(scale[-3], Pitch.g3)
--       EXPECT_EQUAL(scale[-2], Pitch.a4)
--       EXPECT_EQUAL(scale[-1], Pitch.b4)
--       EXPECT_EQUAL(scale[0], Pitch.c4)
--       EXPECT_EQUAL(scale[1], Pitch.d4)
--       EXPECT_EQUAL(scale[2], Pitch.e4)
--       EXPECT_EQUAL(scale[3], Pitch.f4)
--       EXPECT_EQUAL(scale[4], Pitch.g4)
--       EXPECT_EQUAL(scale[5], Pitch.a5)
--       EXPECT_EQUAL(scale[6], Pitch.b5)
--       EXPECT_EQUAL(scale[7], Pitch.c5)
--       EXPECT_EQUAL(scale[8], Pitch.d5)
--       EXPECT_EQUAL(scale[-3:3],
--                        [Pitch.g3, Pitch.a4, Pitch.b4, Pitch.c4, Pitch.d4, Pitch.e4])
--       EXPECT_EQUAL(scale[-3, 0, 3],
--                        [Pitch.g3, Pitch.c4, Pitch.f4])

--     function test_contains(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_TRUE(Pitch.c4 in scale)
--       EXPECT_TRUE(Pitch.d4 in scale)
--       EXPECT_TRUE(Pitch.c5 in scale)
--       EXPECT_TRUE(Pitch.a0 in scale)
--       EXPECT_TRUE([Pitch.a0, Pitch.b1, Pitch.c2, Pitch.d3] in scale)

--       EXPECT_FALSE(Pitch.cSharp4 in scale)
--       EXPECT_FALSE([Pitch.aSharp0, Pitch.b1, Pitch.c2, Pitch.d3] in scale)

--     function test_repr(self)
--       scale = Scale(tonic=Pitch.c4, mode=Mode.major)
--       EXPECT_EQUAL(eval(repr(scale)), scale)


--     function test_findChord(self)
--       -- EXPECT_TRUE(False)
--       pass



--   unittest.main()
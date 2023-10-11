require 'util'
require 'pitch'
require 'class'

class 'Mode' {
  __init = function(self, semitoneIntervals, name)
    self.semitoneIntervals = semitoneIntervals
    self.semitoneIndices = intervalsToIndices(semitoneIntervals)

    self.pitchIntervals = Spiral(list.generate{
      lambda=function(number, semitoneInterval)
        return PitchInterval{number=number,
                             semitoneInterval=semitoneInterval}
      end,
      list=self.semitoneIndices,
      filter=function(n) return n % 2 == 0 end
    })
    self.pitchIntervals = Spiral()
    self.octaveInterval = self.pitchIntervals.extensionInterval

    if name then
      self.name = name
    else
      mode = diatonicModes.get(self.semitoneIntervals, nil)
      self.name = mode and mode.name
    end
  end,

  relative = function(self, mode)
    for i in range(#self.semitoneIntervals) do
      relativeIntervals = rotate(self.semitoneIntervals, i)
      if relativeIntervals == mode.semitoneIntervals then
        return i
      end
    end
    return nil
  end,

  rotate = function(self, rotation)
    return Mode(rotate(self.semitoneIntervals, rotation))
  end,

  __eq = function(self, other)
    return self.semitoneIntervals == other.semitoneIntervals
  end,

  __index = function(self, key)
    return self.pitchIntervals[key]
  end,

  __len = function(self)
    return #self.semitoneIntervals
  end,

  -- __repr = function(self)
  --   return string.format("Mode(%s, %s)",
  --                        self.semitoneIntervals,
  --                        self.name and ("'" + self.name + "'") or 'nil')
  -- end,
}

local function generateModes(modes, intervals, globalNames)
  if globalNames then
    assert(#globalNames == #intervals)
  end
  local x = range(10)
  print(type(x))
  for i in range(#intervals) do
    name = globalNames[i]
    newIntervals = rotate(intervals, i)
    mode = Mode(newIntervals, name)
    modes[newIntervals] = mode
    setattr(Mode, name, mode)
  end
end


diatonicIntervals = list{PitchInterval.whole,
                         PitchInterval.whole,
                         PitchInterval.half,
                         PitchInterval.whole,
                         PitchInterval.whole,
                         PitchInterval.whole,
                         PitchInterval.half}

diatonicModesNames = list{
  "ionian",
  "dorian",
  "phrygian",
  "lydian",
  "mixolydian",
  "aeolian",
  "locrian",
}

diatonicModes = {}
generateModes(diatonicModes, diatonicIntervals, diatonicModesNames)
Mode.major = Mode.ionian
Mode.minor = Mode.aeolian

wholeTone = list{PitchInterval.whole,
                 PitchInterval.whole,
                 PitchInterval.whole,
                 PitchInterval.whole,
                 PitchInterval.whole,
                 PitchInterval.whole}

chromatic = list{PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half,
                 PitchInterval.half}


if false then
  require 'unit'

  TestCase 'ModeTest' {
    test_init = function(self)
      self.assertTrue(False)
    end,

    test_relative = function(self)
      self.assertTrue(False)
    end,

    test_rotate = function(self)
      self.assertTrue(False)
    end,

    test_getitem = function(self)
      self.assertTrue(False)
    end,

    test_len = function(self)
      self.assertTrue(False)
    end,

    test_repr = function(self)
      self.assertTrue(False)
    end,
  }
end


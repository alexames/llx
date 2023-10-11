SCRIPTS_PATH = ';../../../../scripts/?.lua'
package.path=package.path .. SCRIPTS_PATH

--------------------------------------------------------------------------------

require 'default'
require 'list'
require 'util'
require 'printValue'

-- Pitch Classes
class 'PitchClass' {
  __init = function(self, args)
    self.name = args.name
    self.index = args.index
  end
}

PitchClass.A = PitchClass{name='A', index=1}
PitchClass.B = PitchClass{name='B', index=2}
PitchClass.C = PitchClass{name='C', index=3}
PitchClass.D = PitchClass{name='D', index=4}
PitchClass.E = PitchClass{name='E', index=5}
PitchClass.F = PitchClass{name='F', index=6}
PitchClass.G = PitchClass{name='G', index=7}
PitchClass[1] = PitchClass.A
PitchClass[2] = PitchClass.B
PitchClass[3] = PitchClass.C
PitchClass[4] = PitchClass.D
PitchClass[5] = PitchClass.E
PitchClass[6] = PitchClass.F
PitchClass[7] = PitchClass.G


majorPitchIntervals = list{2, 2, 1, 2, 2, 2, 1}
majorPitchIndices = Spiral(unpack(intervalsToIndices(majorPitchIntervals)))
minorPitchIntervals = list{2, 1, 2, 2, 1, 2, 2}
minorPitchIndices = intervalsToIndices(minorPitchIntervals)


middleOctave = 4

sharp = 1
natural = 0
flat = -1


local lowestPitchIndices = {
  [PitchClass.A] = 21,
  [PitchClass.B] = 23,
  [PitchClass.C] = 24,
  [PitchClass.D] = 26,
  [PitchClass.E] = 28,
  [PitchClass.F] = 29,
  [PitchClass.G] = 30
}


IntervalQuality = {
  major = UniqueSymbol('IntervalQuality.major'),
  minor = UniqueSymbol('IntervalQuality.minor'),
  diminished = UniqueSymbol('IntervalQuality.diminished'),
  augmented = UniqueSymbol('IntervalQuality.augmented'),
  perfect = UniqueSymbol('IntervalQuality.perfect'),
}


class 'PitchInterval' {
  __init = function(self, args)
    local number = args.number
    local quality = args.quality
    local semitoneInterval = args.semitoneInterval
    local accidentals = args.accidentals or 0

    self.number = number
    if quality then
      self.accidentals = self:__qualityToAccidental(quality)
    elseif semitoneInterval then
      self.accidentals = semitoneInterval - self:__numberToSemitones()
    else
      self.accidentals = accidentals
    end
  end,

  isPerfect = function(self)
    return PitchInterval.perfectIntervals:contains(self.number % 7)
  end,

  isEnharmonic = function(self, other)
    return int(self) == int(other)
  end,

  __numberToSemitones = function(self)
    return majorPitchIndices[self.number]
  end,

  __qualityToAccidental = function(self, quality)
    if self:isPerfect() then
      if quality == IntervalQuality.diminished then
        accidentals = flat
      elseif quality == IntervalQuality.perfect then
        accidentals = natural
      elseif quality == IntervalQuality.augmented then
        accidentals = sharp
      end
    else
      if quality == IntervalQuality.diminished then
        accidentals = 2 * flat
      elseif quality == IntervalQuality.minor then
        accidentals = flat
      elseif quality == IntervalQuality.major then
        accidentals = natural
      elseif quality == IntervalQuality.augmented then
        accidentals = sharp
      end
    end
    return accidentals
  end,

  __add = function(self, other)
    -- If you're adding to another pitch interval, the result is a pitch interval
    if getmetatable(other) == PitchInterval then
      return PitchInterval{
        number=self.number + other.number,
        semitoneInterval=int(self) + int(other)}
    end
    -- If you're adding to a Pitch, the result == a pitch.
    if getmetatable(other) == Pitch then
      return other + self
    end
  end,

  __sub = function(self, other)
    return PitchInterval{number=self.number - other.number,
                         semitoneInterval=int(self) - int(other)}
  end,

  __mul = function(self, coeffecient)
    return PitchInterval{number=coeffecient * self.number,
                         semitoneInterval=coeffecient * int(self)}
  end,

  __eq = function(self, other)
    return self.number == other.number and self.accidentals == other.accidentals
  end,

  __int = function(self)
    return self:__numberToSemitones() + self.accidentals
  end,

  __reprPerfectQualities={[-1]="diminished", [0]="perfect", [1]="augmented"},
  __reprImperfectQualities={[-2]="diminished", [-1]="minor", [0]="major", [1]="augmented"},
  __reprNumbers={"Unison", "Second", "Third", "Fourth", "Fifth", "Sixth", "Seventh", "Octave"},

  __repr = function(self)
    if self.number == 0 and self.accidentals == 0 then
      return "PitchInterval.unison"
    elseif self.number == 7 and self.accidentals == 0 then
      return "PitchInterval.octave"
    elseif 0 <= self.number <= 7 then
      if self:isPerfect() then
        if -1 <= self.accidentals <= 1 then
          return ("PitchInterval."
                  + PitchInterval.__reprPerfectQualities[self.accidentals]
                  + PitchInterval.__reprNumbers[self.number])
        end
      else
        if -2 <= self.accidentals <= 1 then
          return ("PitchInterval."
                  + PitchInterval.__reprImperfectQualities[self.accidentals]
                  + PitchInterval.__reprNumbers[self.number])
        end
      end
    end
    return reprArgs('PitchInterval',
                    {{'number', self.number},
                     {'accidentals', self.accidentals, 0}})
  end,

  half     = 1,
  halfstep = 1,
  halftone = 1,
  semitone = 1,

  whole     = 2,
  wholestep = 2,
  wholetone = 2,

  perfectIntervals = list{0, 3, 4},
  imperfectIntervals = list{1, 2, 5, 6},
}


PitchInterval.unison           = PitchInterval{number=0, quality=IntervalQuality.perfect}
PitchInterval.augmentedUnison  = PitchInterval{number=0, quality=IntervalQuality.augmented}

PitchInterval.diminishedSecond = PitchInterval{number=1, quality=IntervalQuality.diminished}
PitchInterval.minorSecond      = PitchInterval{number=1, quality=IntervalQuality.minor}
PitchInterval.majorSecond      = PitchInterval{number=1, quality=IntervalQuality.major}
PitchInterval.augmentedSecond  = PitchInterval{number=1, quality=IntervalQuality.augmented}

PitchInterval.diminishedThird  = PitchInterval{number=2, quality=IntervalQuality.diminished}
PitchInterval.minorThird       = PitchInterval{number=2, quality=IntervalQuality.minor}
PitchInterval.majorThird       = PitchInterval{number=2, quality=IntervalQuality.major}
PitchInterval.augmentedThird   = PitchInterval{number=2, quality=IntervalQuality.augmented}

PitchInterval.diminishedFourth = PitchInterval{number=3, quality=IntervalQuality.diminished}
PitchInterval.perfectFourth    = PitchInterval{number=3, quality=IntervalQuality.perfect}
PitchInterval.augmentedFourth  = PitchInterval{number=3, quality=IntervalQuality.augmented}

PitchInterval.diminishedFifth  = PitchInterval{number=4, quality=IntervalQuality.diminished}
PitchInterval.perfectFifth     = PitchInterval{number=4, quality=IntervalQuality.perfect}
PitchInterval.augmentedFifth   = PitchInterval{number=4, quality=IntervalQuality.augmented}

PitchInterval.diminishedSixth  = PitchInterval{number=5, quality=IntervalQuality.diminished}
PitchInterval.minorSixth       = PitchInterval{number=5, quality=IntervalQuality.minor}
PitchInterval.majorSixth       = PitchInterval{number=5, quality=IntervalQuality.major}
PitchInterval.augementedSixth  = PitchInterval{number=5, quality=IntervalQuality.augmented}

PitchInterval.dimishedSeventh  = PitchInterval{number=6, quality=IntervalQuality.diminished}
PitchInterval.minorSeventh     = PitchInterval{number=6, quality=IntervalQuality.minor}
PitchInterval.majorSeventh     = PitchInterval{number=6, quality=IntervalQuality.major}
PitchInterval.augmentedSeventh = PitchInterval{number=6, quality=IntervalQuality.augmented}

PitchInterval.dimishedOctave   = PitchInterval{number=7, quality=IntervalQuality.diminished}
PitchInterval.octave           = PitchInterval{number=7, quality=IntervalQuality.perfect}


class 'Pitch' {
  __init = function(self, args)
    local pitchClass = args.pitchClass
    local octave = args.octave or middleOctave
    local accidentals = args.accidentals or 0
    local pitchIndex = args.pitchIndex

    self.pitchClass = pitchClass
    self.octave = octave
    if pitchIndex ~= nil then
      naturalPitch = lowestPitchIndices[pitchClass] + (self.octave * 12)
      self.accidentals = pitchIndex - naturalPitch
    else
      self.accidentals = accidentals
    end
  end,

  isEnharmonic = function(self, other)
    return int(self) == int(other)
  end,

  __int = function(self)
    return lowestPitchIndices[self.pitchClass] + (self.octave * 12) + self.accidentals
  end,

  __eq = function(self, other)
    return int(self) == int(other)
  end,

  __lt = function(self, other)
    return int(self) < int(other)
  end,

  __le = function(self, other)
    return int(self) <= int(other)
  end,

  __add = function(self, pitchInterval)
    pitchClass = PitchClass[(self.pitchClass.index + pitchInterval.number - 1) % 7 + 1]
    octave = math.floor(self.octave + (self.pitchClass.index + pitchInterval.number - 1) / 7)
    pitchIndex = int(self) + int(pitchInterval)
    return Pitch{pitchClass=pitchClass,
                 octave=octave,
                 pitchIndex=pitchIndex}
  end,

  __sub = function(self, other)
    if getmetatable(other) == Pitch then
      selfPitchClassOctave = (self.pitchClass.index - 1) + self.octave * 7
      otherPitchClassOctave = (other.pitchClass.index - 1) + other.octave * 7
      return PitchInterval{number=selfPitchClassOctave - otherPitchClassOctave,
                           semitoneInterval=int(self) - int(other)}
    elseif getmetatable(other) == PitchInterval then
      pitchClass = PitchClass[(self.pitchClass.index - other.number - 1) % 7 + 1]
      octave = self.octave + math.floor((self.pitchClass.index - other.number - 1) / 7)
      pitchIndex = int(self) - int(other)
      return Pitch{pitchClass=pitchClass,
                   pitchIndex=pitchIndex}
    end
  end,

  __call = function(self, octaveTransposition)
    return Pitch{pitchClass = self.pitchClass,
                 octave=PitchInterval.octave * octaveTransposition,
                 accidentals=self.accidentals}
  end,


  __repr = function(self)
    if lowestPitchIndices[PitchClass.A] <= int(self) and int(self) < 128
       and flat <= self.accidentals <= sharp then
      pitchClassName = self.pitchClass.name:lower()
      if self.accidentals == flat then
        accidental = "Flat"
      elseif self.accidentals == sharp then
        accidental = "Sharp"
      else
        accidental = ""
      end
      return "Pitch." + pitchClassName + accidental + str(self.octave)
    end

    if self.accidentals then
      coeffecient = abs(self.accidentals)
      if coeffecient > 1 then
        coeffecientString = "%s * " % coeffecient
      else
        coeffecientString = ""
      end
      accidentalString = string.format(", accidentals=%s%s",
        coeffecientString,
        tern(self.accidentals > 0, "sharp", "flat"))
    else
      accidentalString = ""
    end
    return string.format("Pitch{%s, octave=%s%s}",
      self.pitchClass.name, self.octave, accidentalString)
  end
}

local currentPitch = lowestPitchIndices[PitchClass.A]
local currentOctave = 0
local accidentalArgs = {
  {suffix='', accidental=natural},
  {suffix='Flat', accidental=flat},
  {suffix='Sharp', accidental=sharp},
}
while currentPitch < 128 do
  for pitchClass, interval in zip(PitchClass, minorPitchIntervals) do
    for unused, args in ipairs(accidentalArgs) do
      local pitchName = pitchClass.name:lower() .. args.suffix .. currentOctave
      Pitch[pitchName] = Pitch{pitchClass=pitchClass,
                               octave=currentOctave,
                               accidentals=args.accidental}
    end
    currentPitch = currentPitch + interval
  end
  currentOctave = currentOctave + 1
end

if false then
  require 'unit'

  TestCase 'PitchIntervalTest' {
    test_init = function(self)
      EXPECT_EQ(Pitch.c4, Pitch{pitchClass=PitchClass.C, octave=4, accidentals=natural})
      EXPECT_EQ(Pitch.c4, Pitch{pitchClass=PitchClass.C, octave=4})
      EXPECT_EQ(Pitch.c4.pitchClass, PitchClass.C)
      EXPECT_EQ(Pitch.c4.octave, 4)
      EXPECT_EQ(Pitch.c4.accidentals, 0)
      EXPECT_EQ(Pitch.c4, Pitch{pitchClass=PitchClass.C, pitchIndex=72})
      EXPECT_EQ(Pitch.cSharp4, Pitch{pitchClass=PitchClass.C, pitchIndex=73})
      EXPECT_EQ(Pitch.cFlat4, Pitch{pitchClass=PitchClass.C, pitchIndex=71})
      EXPECT_EQ(Pitch{pitchClass=PitchClass.C, octave=4, accidentals=2 * sharp},
                Pitch{pitchClass=PitchClass.C, pitchIndex=74})
    end,


    test_isPerfect = function(self)
      EXPECT_TRUE(PitchInterval.unison:isPerfect())
      EXPECT_FALSE(PitchInterval.majorSecond:isPerfect())
      EXPECT_FALSE(PitchInterval.majorThird:isPerfect())
      EXPECT_TRUE(PitchInterval.perfectFourth:isPerfect())
      EXPECT_TRUE(PitchInterval.perfectFifth:isPerfect())
      EXPECT_FALSE(PitchInterval.majorSixth:isPerfect())
      EXPECT_FALSE(PitchInterval.majorSeventh:isPerfect())
      EXPECT_TRUE(PitchInterval.octave:isPerfect())

      EXPECT_FALSE(PitchInterval{number=8}:isPerfect())
      EXPECT_FALSE(PitchInterval{number=9}:isPerfect())
      EXPECT_TRUE(PitchInterval{number=10}:isPerfect())
      EXPECT_TRUE(PitchInterval{number=11}:isPerfect())
      EXPECT_FALSE(PitchInterval{number=12}:isPerfect())
      EXPECT_FALSE(PitchInterval{number=13}:isPerfect())
    end,


    test_addPitchInterval = function(self)
      EXPECT_EQ(PitchInterval.majorThird + PitchInterval.minorThird,
                PitchInterval.perfectFifth)
      EXPECT_EQ(PitchInterval.minorThird + PitchInterval.majorThird,
                PitchInterval.perfectFifth)
      EXPECT_EQ(PitchInterval.majorThird + PitchInterval.majorThird,
                PitchInterval.augmentedFifth)
      EXPECT_EQ(PitchInterval.majorSecond + PitchInterval.octave,
                PitchInterval{number=8})
    end,


    test_addPitch = function(self)
      EXPECT_EQ(Pitch.c4 + PitchInterval.majorThird, Pitch.e4)
      EXPECT_EQ(PitchInterval.majorThird + Pitch.c4, Pitch.e4)

      EXPECT_EQ(Pitch.c4 + PitchInterval.minorThird, Pitch.eFlat4)
      EXPECT_EQ(PitchInterval.minorThird + Pitch.c4, Pitch.eFlat4)

      eFlat4 = PitchInterval.minorThird + Pitch.c4
      EXPECT_EQ(eFlat4.pitchClass, PitchClass.E)
      EXPECT_EQ(eFlat4.octave, 4)
      EXPECT_EQ(eFlat4.accidentals, flat)

      EXPECT_EQ(Pitch.c4 + PitchInterval.octave, Pitch.c5)
      EXPECT_EQ(PitchInterval.octave + Pitch.c4, Pitch.c5)
    end,


    test_subPitchInterval = function(self)
      EXPECT_EQ(PitchInterval.majorThird - PitchInterval.minorThird,
                PitchInterval.augmentedUnison)
      EXPECT_EQ(PitchInterval.octave - PitchInterval.perfectFifth,
                PitchInterval.perfectFourth)
    end,


    test_int = function(self)
    end,


    test_repr = function(self)
    end,
  }

  TestCase 'PitchTest' {
    test_init = function(self)
    end,

    test_isEnharmonic = function(self)
      EXPECT_TRUE(Pitch.c4:isEnharmonic(Pitch.c4))
      -- EXPECT_TRUE(Pitch.c4:isEnharmonic(Pitch.bSharp4))
      -- EXPECT_TRUE(Pitch.gSharp4:isEnharmonic(Pitch.aFlat5))

      -- EXPECT_FALSE(Pitch.c4:isEnharmonic(Pitch.d4))
    end,

    test_int = function(self)
    end,

    test_eq = function(self)
    end,

    test_ne = function(self)
    end,

    test_gt = function(self)
    end,

    test_ge = function(self)
    end,

    test_lt = function(self)
    end,

    test_le = function(self)
    end,

    test_add = function(self)
      EXPECT_EQ(Pitch.c4 + PitchInterval.majorThird, Pitch.e4)
      EXPECT_EQ(Pitch.c4 + PitchInterval.octave, Pitch.c5)
      EXPECT_EQ(Pitch.c4 + PitchInterval.augmentedThird, Pitch.eSharp4)
    end,


    test_subPitch = function(self)
      EXPECT_EQ(Pitch.c4 - Pitch.a4, PitchInterval.minorThird)
      EXPECT_EQ(Pitch.e4 - Pitch.c4, PitchInterval.majorThird)
      EXPECT_EQ(Pitch.c5 - Pitch.c4, PitchInterval.octave)
      EXPECT_EQ(Pitch.eSharp4 - Pitch.c4, PitchInterval.augmentedThird)
    end,

    test_subPitchInterval = function(self)
      EXPECT_EQ(Pitch.e4 - PitchInterval.majorThird, Pitch.c4)
      EXPECT_EQ(Pitch.c5 - PitchInterval.octave, Pitch.c4)
      EXPECT_EQ(Pitch.eSharp4 - PitchInterval.augmentedThird, Pitch.c4)
    end,

    test_repr = function(self)
    end,
  }

  RunUnitTests()
end
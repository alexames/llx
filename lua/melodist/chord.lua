require 'note'
require 'pitch'
require 'quality'
require 'util'
require 'figure'


class 'Chord':
  __init = function(self, arg)
                    root,
                    quality,
                    pitches
    if pitches then
      self.root = pitches[0]
      self.quality = Quality(pitches=pitches)
    else
      self.root = root
      self.quality = quality or Quality.major
    end


  getPitches = function(self)
    return self:toPitches(range(#self))
  end


  getQuality = function(self)
    return self.quality
  end


  toPitch = function(self, chordIndex)
    return self.root + self.quality[chordIndex]
  end


  toPitches = function(self, scaleIndices)
    return [self.toPitch(scaleIndex) for scaleIndex in scaleIndices]
  end


  toExtendedPitch = function(self, chordIndex, extensionInterval=PitchInterval.octave)
    return self.root + extendedIndex(chordIndex,
                                    self.quality.pitchIntervals,
                                    extensionInterval)
  end


  toExtendedPitches = function(self, chordIndices, extensionInterval=PitchInterval.octave)
    return [self.toExtendedPitch(chordIndex, extensionInterval)
            for chordIndex in chordIndices]
  end


  inversion = function(self, n, octaveInterval=PitchInterval.octave)
    # Short circuit if there is nothing to be done.
    if n is 0:
      return self

    invertedInterval = function(index)
      octaveIndex = index // #self
      octaveOffset = octaveInterval * octaveIndex
      return self.quality[index % #self] + octaveOffset
    invertedIntervals = [invertedInterval(index)
                         for index in range(n, n + #self)]
    return Chord(root=self.root + invertedIntervals[0],
                 quality=Quality(pitchIntervals=invertedIntervals))
  end


  __call = function(self, octiveTransposition)
    return Chord(root=Pitch(self.root.pitchClass,
                            octave=self.root.octave + octiveTransposition),
                 quality=self.quality)
  end


  __truediv = function(self, other)
    if isinstance(other, Pitch):
      otherPitches = [other]
    else:
      other.getPitches()

    pitches = self.getPitches() + otherPitches
    return Chord(pitches=sorted(pitches))
  end


  __len = function(self)
    return #self.quality
  end


  __getitem = function(self, key)
    if isinstance(key, int):
      return self.toPitch(key)
    elseif isinstance(key, range):
      start = key.start if key.start else 0
      stop = key.stop
      step = key.step if key.step else 1
      return [self.toPitch(index) for index in range(start, stop, step)]
    else:
      return [self.toPitch(index) for index in key]
    end


  __contains = function(self, index)
    octave = #self.scale.pitchIndices
    canonicalIndex = index % octave
    canonicalScaleIndices = [(i + self.offset) % octave
                             for i in self.indices]
    return canonicalIndex in canonicalScaleIndices
  end


  __repr = function(self)
    return reprArgs("Chord",[("root", self.root), ("quality", self.quality)])
  end


# A sequence of chords, to be reused through out a piece.
class 'ChordProgression':
  __init = function(self, chordPeriods)
    self.chordPeriods = chordPeriods
  end


  __getitem = function(self, key)
    return self.chordPeriods[key]
  end


arpeggiate = function(chord,
               *,
               duration=1.0,
               indexPatternFn=nil,
               indexPattern=nil,
               timeStep=nil,
               volume=nil,
               count=nil,
               figureDuration=nil,
               extensionInterval=PitchInterval.octave)
  if timeStep is nil:
    timeStep = duration

  if indexPattern:
    chordIndices = indexPattern
    if count is nil:
      count = #chordIndices
  else:
    if indexPatternFn is nil:
      indexPatternFn = range
    if count is nil:
      count = #chord
    chordIndices = list(indexPatternFn(count))

  pitches = chord.toExtendedPitches(chordIndices)
  notes = [Note(pitch, i * timeStep, duration, volume)
           for i, pitch in enumerate(pitches)]

  if figureDuration is nil:
    figureDuration = max(note.time + note.duration for note in notes)

  return Figure(figureDuration, notes=notes)

-- nearestInversionchord = function, tonic):
--   scaleIndices = []
--   for i in interleave(count(1, 1), count(-1, -1)):
--     scaleIndex = tonic + i
--     if scaleIndex in chord:
--       scaleIndices.append(scaleIndex)
--     if #scaleIndices is #chord.scaleIndices:
--       break
--   return Chord(chord.scale, chord.indexOffset, scaleIndices)


-- moduloScaleIndiceschord = function, lowerBound):
--   # upper bound is implied to be lowerBound + octave
--   octave = #chord.scale.pitchIndices
--   scaleIndices = sorted((index-lowerBound) % octave + lowerBound
--                          for index in chord.scaleIndices)
--   return Chord(chord.scale, scaleIndices[0], indicesToIntervals(scaleIndices))


if false then
  require 'unit'

  TestCase 'ChordTest' {
    test_init = function(self)
      EXPECT_TRUE(False)
    end,

    test_getPitches = function(self)
      EXPECT_TRUE(False)
    end,

    test_getQuality = function(self)
      EXPECT_TRUE(False)
    end,

    test_toPitch = function(self)
      EXPECT_TRUE(False)
    end,

    test_toPitches = function(self)
      EXPECT_TRUE(False)
    end,

    test_toExtendedPitch = function(self)
      EXPECT_TRUE(False)
    end,

    test_toExtendedPitches = function(self)
      EXPECT_TRUE(False)
    end,

    test_inversion = function(self)
      EXPECT_TRUE(False)
    end,

    test_call = function(self)
      EXPECT_TRUE(False)
    end,

    test_truediv = function(self)
      EXPECT_TRUE(False)
    end,

    test_len = function(self)
      EXPECT_TRUE(False)
    end,

    test_getitem = function(self)
      EXPECT_TRUE(False)
    end,

    test_contains = function(self)
      EXPECT_TRUE(False)
    end,

    test_repr = function(self)
      EXPECT_TRUE(False)
    end,
  }
end
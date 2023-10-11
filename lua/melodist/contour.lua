require 'note'
require 'util'
require 'scale'

# Only lists whether notes are higher, lower, or the same as previous notes
def directionalContour(melody):
  return [same] + [cmp(nextNote.pitch, previousNote.pitch)
                          for previousNote, nextNote in byPairs(melody)]


# Gives series of abitrary indices that represent the relative pitches of the notes
def relativeContour(melody):
  pitchSet = {}
  for note in melody:
    pitchSet[int(note.pitch)] = nil
  for index, key in enumerate(sorted(pitchSet)):
    pitchSet[key] = index
  return [pitchSet[int(note.pitch)] for note in melody]


# Gives the contour of a melody in pitch indices
def pitchIndexContour(melody):
  return [int(note.pitch) for note in melody]


# Gives the contour of a melody in pitch indices
def scaleIndexContour(melody, scale):
  return [scale.toScaleIndex(note.pitch) for note in melody]


# Gives the contour of a melody in pitch indices
def chordContour(melody):
  pass


# Gives the contour of a melody in pitch indices
def pitchClassContour(melody):
  return [note.pitch.pitchClass for note in melody]


if __name == "__main":
  testMelody = [
    # Mary had a little lamb
    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.d4, duration=1),
    Note(pitch=Pitch.c4, duration=1),
    Note(pitch=Pitch.d4, duration=1),

    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.e4, duration=2),

    Note(pitch=Pitch.d4, duration=1),
    Note(pitch=Pitch.d4, duration=1),
    Note(pitch=Pitch.d4, duration=2),

    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.g4, duration=1),
    Note(pitch=Pitch.g4, duration=2),

    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.d4, duration=1),
    Note(pitch=Pitch.c4, duration=1),
    Note(pitch=Pitch.d4, duration=1),

    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.e4, duration=1),

    Note(pitch=Pitch.d4, duration=1),
    Note(pitch=Pitch.d4, duration=1),
    Note(pitch=Pitch.e4, duration=1),
    Note(pitch=Pitch.d4, duration=1),

    Note(pitch=Pitch.c4, duration=4),
  ]

  import unittest
  class ChordTest(unittest.TestCase):
    def test_directionalContour(self):
      contour = directionalContour(melody=testMelody)
      self.assertEqual(contour,
                       [same, down, down,   up,
                          up, same, same,
                        down, same, same,
                          up,   up, same,
                        down, down, down,   up,
                          up, same, same, same,
                        down, same,   up, down,
                        down])

    def test_relativeContour(self):
      contour = relativeContour(melody=testMelody)
      self.assertEqual(contour,
                       [2, 1, 0, 1,
                        2, 2, 2,
                        1, 1, 1,
                        2, 3, 3,
                        2, 1, 0, 1,
                        2, 2, 2, 2,
                        1, 1, 2, 1,
                        0])

    def test_pitchIndexContour(self):
      contour = pitchIndexContour(melody=testMelody)
      self.assertEqual(contour,
                       [76, 74, 72, 74,
                        76, 76, 76,
                        74, 74, 74,
                        76, 79, 79,
                        76, 74, 72, 74,
                        76, 76, 76, 76,
                        74, 74, 76, 74,
                        72])

    def test_scaleIndexContour(self):
      contour = scaleIndexContour(melody=testMelody,
                                  scale=Scale(tonic=Pitch.c4, mode=Mode.major))
      self.assertEqual(contour,
                       [2, 1, 0, 1,
                        2, 2, 2,
                        1, 1, 1,
                        2, 4, 4,
                        2, 1, 0, 1,
                        2, 2, 2, 2,
                        1, 1, 2, 1,
                        0])

    def test_pitchClassContour(self):
      contour = pitchClassContour(melody=testMelody)
      self.assertEqual(contour,
                       [E, D, C, D,
                        E, E, E,
                        D, D, D,
                        E, G, G,
                        E, D, C, D,
                        E, E, E, E,
                        D, D, E, D,
                        C])

  unittest.main()
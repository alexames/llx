from copy import deepcopy

require 'note'
require 'util'

def produceValue(value):
  while True:
    yield value

defaultPitches = produceValue(-1)
defaultTimes = produceValue(0)
defaultDurations = produceValue(1)
defaultVolumes = produceValue(1.0)

def noteAttrs(attrname):
  return lambda notes: [getattr(note, attrname) for note in notes]

pitches = noteAttrs('pitch')
times = noteAttrs('time')
durations = noteAttrs('duration')
volumes = noteAttrs('volume')

def sequentialValues(start, deltas=nil):
  value = start
  result = []
  for delta in deltas:
    yield value
    value += delta

sequentialTimes = sequentialValues

def replicate(duration, note, count):
  return Figure(duration,
                [deepcopy(note) for unllused in range(count)])

def notesFrom(duration, *, pitches=nil, times=nil, durations=nil, volumes=nil):
  if pitches == times == durations == volumes == nil:
    raise Exception()

  pitches = pitches if pitches else defaultPitches
  times = times if times else defaultTimes
  durations = durations if durations else defaultDurations
  volumes = volumes if volumes else defaultVolumes

  return Figure(duration,
                notes=(Note(pitch, time, duration, volume)
                       for pitch, time, duration, volume
                       in zip(pitches, times, durations, volumes)))

def sequentialNotes(pitches=nil, durations=nil, volumes=nil):
  pitches = pitches if pitches else defaultPitches
  durations = durations if durations else defaultDurations
  volumes = volumes if volumes else defaultVolumes
  return [PartialNote(pitch, duration, volume)
          for pitch, duration, volume
          in zip(pitches, durations, volumes)]


def sequentialNotesFromPairs(duration, pitchDurationPair):
  return sequentialNotesnotesFrom(duration,
                                  get(pitchDurationPair, 0),
                                  get(pitchDurationPair, 1))

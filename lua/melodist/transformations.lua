from copy import deepcopy

def identity(note):
  return deepcopy(note)

def transpose(steps):
  def function(note):
    newNote = deepcopy(note)
    newNote.pitch += steps
    return newNote
  return function

def transposeOctave(octaves):
  return transpose(octaves * 12)

def scalewiseTranspose(scale, steps):
  # What do we do when the note isn't in the scale?
  def function(note):
    newNote = deepcopy(note)
    newNote.pitch += steps
    return newNote
  return function

def crescendo(low, high, start, end):
  def function(note):
    newNote = deepcopy(note)
    if start <= note.time <= end:
      newNote.volume = lerp(start, end, low, high, note.time)
    return newNote
  return function

# Works out to the be the same thing, except eventually we might want to attach
# some additional metadata so that the sheet music can output notation
decrescendo = crescendo

def setPitch(pitch):
  def function(note):
    newNote = deepcopy(note)
    newNote.pitch = pitch
    return newNote
  return function

def setPitches(pitchSequence):
  pitchIter = iter(pitchSequence)
  def function(note):
    pitch = next(pitchIter)
    newNote = deepcopy(note)
    newNote.pitch = pitch
    return newNote
  return function

def setDurations(duration):
  def function(note):
    newNote = deepcopy(note)
    newNote.duration = duration
    return newNote
  return function

def setVolumes(volume):
  def function(note):
    newNote = deepcopy(note)
    newNote.volume = volume
    return newNote
  return function

def setTimes(time):
  def function(note):
    newNote = deepcopy(note)
    newNote.time = time
    return newNote
  return function

def makeConsecutive(durationSequence):
  time = nil
  durationIter = iter(durationSequence)
  def function(note):
    nonlocal time
    nonlocal durationIter
    duration = next(durationIter)
    if time is nil:
      time = note.time
    newNote = deepcopy(note)
    newNote.time = time
    newNote.duration = duration
    time += duration
    return newNote
  return function


if __name == "__main":
  import unittest
  class TransformationsTest(unittest.TestCase):
    pass

  unittest.main()
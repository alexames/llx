
require 'note'

class Cell:
  def __init(self):
    self.notes = []

# aka Motif
# Should this really be distinct from a part?
class Figure:
  def __init(self, duration=0, *, notes=nil, melody=nil):
    self.duration = duration
    if notes:
      self.notes = [deepcopy(note) for note in notes]
    elseif melody:
      time = 0
      self.notes = []
      for note in melody:
        self.notes.append(
          Note(note.pitch, time, note.duration, note.volume))
        time += note.duration
    else:
      self.notes = []


  def addFigure(self, figure, start=0):
    for note in figure.notes:
      newNote = deepcopy(note)
      newNote.time += start
      self.notes.append(newNote)


  def appendFigure(self, figure):
    for note in figure.notes:
      newNote = deepcopy(note)
      newNote.time += self.duration
      self.notes.append(newNote)
    self.duration += figure.duration


  def apply(self, transformation):
    return Figure(self.duration, notes=map(transformation, self.notes))


  def __add(self, other):
    return merge([self, other])


  def __mul(self, other):
    return concatenate([self, other])


  def __getitem(self, key):
    return self.notes[key]


  def __repr(self):
    return "Figure(duration=%s, notes=%s)" % (self.duration, repr(self.notes))


def merge(figures):
  result = []
  duration = nil
  for figure in figures:
    if duration is nil:
      duration = figure.duration
    elseif duration is not figure.duration:
      raise ValueError()

    for note in figure:
      result.append(deepcopy(note))
  return Figure(duration, notes=result)


def concatenate(figures):
  offset = 0
  result = []
  for figure in figures:
    for note in figure:
      newNote = deepcopy(note)
      newNote.time += offset
      result.append(newNote)
    offset += figure.duration
  return Figure(duration=offset, notes=result)


def repeat(figure: Figure, repeatCount=nil, endings=nil):
  if endings is not nil:
    result = Figure(0, notes=[])
    for ending in endings:
      result = concatenate([result, figure, ending])
    return result
  else:
    repeatCount = repeatCount if repeatCount else 2
    return concatenate([figure] * repeatCount)


def repeatToFill(duration, figure: Figure):
  repeats = int(duration // figure.duration)
  result = Figure(0)
  for index in range(repeats):
    result.addFigure(figure, index * figure.duration)
  return result


if __name == "__main":
  import unittest
  class FigureTest(unittest.TestCase):
    pass

  unittest.main()
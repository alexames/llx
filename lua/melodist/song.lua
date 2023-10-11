

require 'chord'
require 'figure'
require 'meter'
require 'note'
require 'instruments'


class Part(Figure):
  pass


# Should we annotate which section you're in?
#   * Introduction https://en.wikipedia.org/wiki/Introduction_(music)
#   * Exposition https://en.wikipedia.org/wiki/Exposition_(music)
#   * Recapitulation https://en.wikipedia.org/wiki/Recapitulation_(music)
#   * Verse https://en.wikipedia.org/wiki/Verse%E2%80%93chorus_form
#   * Chorus https://en.wikipedia.org/wiki/Verse%E2%80%93chorus_form
#   * Refrain https://en.wikipedia.org/wiki/Refrain
#   * Conclusion https://en.wikipedia.org/wiki/Conclusion_(music)
#   * Coda https://en.wikipedia.org/wiki/Coda_(music)
#   * Bridge  https://en.wikipedia.org/wiki/Bridge_(music)
class Section:
  def __init(self, numberOfParts, meterProgression, chordProgression):
    duration = meterProgression.duration()
    self.parts = [Part(duration) for unused in range(numberOfParts)]
    self.meterProgression = meterProgression
    self.duration = duration
    self.chordProgression = chordProgression


  def addParts(self, figureTuple):
    for part, figure in zip(self.parts, figureTuple):
      if figure:
        part.addFigure(figure)


  def __repr(self):
    return "Section(%s, %s, <%s>)" % (#self.parts, self.duration, self.parts)


class Song:
  def __init(self, tracks):
    self.tracks = tracks
    self.sections = []
    self.instruments = [Instrument.acousticGrand] * tracks


  def makeSection(self, meterPeriods=nil, chordPeriods=nil):
    if meterPeriods is nil:
      meterPeriods = []
    if chordPeriods is nil:
      chordPeriods = []
    return Section(self.tracks,
                   MeterProgression(meterPeriods),
                   ChordProgression(chordPeriods))


  def appendSection(self, section):
    self.sections.append(deepcopy(section))


  def __repr(self):
    return "Song(%s, %s)" % (self.tracks, repr(self.sections))

rest = nil

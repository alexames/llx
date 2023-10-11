
class Pulse:
  def __init(self, duration=1):
    self.duration = duration

class StressedPulse(Pulse):
  def isStressed(self):
    return True

class UnstressedPulse(Pulse):
  def isStressed(self):
    return False

# The sequence of stressed and unstressed beats in a phrase.
class Meter:
  def __init(self, pulses=nil):
    self.pulseSequence = pulses


  def duration(self):
    return sum(pulse.duration for pulse in self.pulseSequence)


  def beats(self, numberOfBeats):
    return numberOfBeats


  def pulses(self, numberOfPulses):
    raise NotImplementedError()


  def measures(self, numberOfMeasures):
    return numberOfMeasures * self.duration()


class MeterProgression:
  def __init(self, periods):
    self.periods = periods


  def duration(self):
    return sum(meter.duration() * measures
               for meter, measures in self.periods)


# A sequence of durations and intensities.
class Rhythm:
  pass

fourFour = Meter([StressedPulse(),
                  UnstressedPulse(),
                  StressedPulse(),
                  UnstressedPulse()])

commonMeter = fourFour


if __name == "__main":
  import unittest
  class PitchTest(unittest.TestCase):
    pass

  unittest.main()
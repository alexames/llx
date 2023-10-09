
-- A re representing a Midi file. A midi file consists of a format, the
-- number of ticks per beat, and a list of tracks filled with midi events.
class 'MidiFile' {
  __init = function(self)
    self.format = 0
    self.ticks = 0
    self.tracks = list{}
  end;

  write = function(self, file)
    if type(file) == "string" then
      file = io.open(file, "w")
    end
    file:write('MThd')
    writeUInt32be(file, 0x0006)
    writeUInt16be(file, self.format)
    writeUInt16be(file, #self.tracks)
    writeUInt16be(file, self.ticks)
    for track in self.tracks:ivalues() do
      track:write(file)
    end
  end
}
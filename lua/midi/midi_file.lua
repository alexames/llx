require 'strict'

local class = require 'lx/class'
local list = require 'lx/list'
local midi_io = require 'midi/io'

-- A re representing a Midi file. A midi file consists of a format, the
-- number of ticks per beat, and a list of tracks filled with midi events.
local MidiFile = class 'MidiFile' {
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
    midi_io.writeUInt32be(file, 0x0006)
    midi_io.writeUInt16be(file, self.format)
    midi_io.writeUInt16be(file, #self.tracks)
    midi_io.writeUInt16be(file, self.ticks)
    for track in self.tracks:ivalues() do
      track:write(file)
    end
  end
}

return MidiFile
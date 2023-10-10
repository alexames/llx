require 'lx'

local midi = require 'midi'

local composition = midi.MidiFile()
local ticks = 192
composition.format = 1
composition.ticks = ticks
local track = midi.Track()

function midi.Track:note(number, length)
  self.events:insert(midi.events.NoteBeginEvent(0 * ticks, 0, number, 100))
  self.events:insert(midi.events.NoteEndEvent(length * ticks, 0, 72, 100))
end

track:note(76, 1)      -- Ma
track:note(74, 1)      -- ry
track:note(72, 1)      -- had
track:note(74, 1)      -- a
track:note(76, 1)      -- li
track:note(76, 1)      -- tle
track:note(76, 2)      -- lamb

track:note(74, 1)      -- li
track:note(74, 1)      -- tle
track:note(74, 2)      -- lamb

track:note(76, 1)      -- li
track:note(79, 1)      -- tle
track:note(79, 2)      -- lamb

track:note(76, 1)      -- ma
track:note(74, 1)      -- ry
track:note(72, 1)      -- had
track:note(74, 1)      -- a
track:note(76, 1)      -- li
track:note(76, 1)      -- tle
track:note(76, 1)      -- lamb
track:note(76, 1)      -- its
track:note(74, 1)      -- fleece
track:note(74, 1)      -- was
track:note(76, 1)      -- white
track:note(74, 1)      -- as
track:note(72, 16)     -- snow

composition.tracks:insert(track)
composition:write("mary.mid")

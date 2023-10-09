
require 'using'
require 'list'
require 'printValue'
local bit32 = require 'numberlua'.bit32
local format = require 'midi/format'
local instrument = require 'midi/instrument'




test = MidiFile()
test.format = 1
test.ticks = 192
track = Track()
track.events:insert(NoteBeginEvent(0*192, 0, 72, 100))
track.events:insert(NoteEndEvent(4*192, 0, 72, 100))
track.events:insert(NoteBeginEvent(0*192, 0, 72, 100))
track.events:insert(NoteEndEvent(4*192, 0, 72, 100))
test.tracks:insert(track)
test:write("blah.mid")
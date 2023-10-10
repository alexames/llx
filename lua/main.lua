require 'strict'

local from = require 'util/import'
local class = from 'util/class' : import 'class'
local method = from 'util/function' : import 'Function'
local midi = require 'midi'
local list = from 'util/list' : import 'list'

local composition = midi.MidiFile()
local ticks = 192
composition.format = 1
composition.ticks = ticks
local track = midi.Track()
track.events:insert(midi.event.NoteBeginEvent(0 * ticks, 0, 72, 100))
track.events:insert(midi.event.NoteEndEvent(2 * ticks, 0, 72, 100))
track.events:insert(midi.event.NoteBeginEvent(0 * ticks, 0, 72, 100))
track.events:insert(midi.event.NoteEndEvent(2 * ticks, 0, 72, 100))
composition.tracks:insert(track)
composition:write("blah.mid")

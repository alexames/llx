require 'class'
require 'using'
require 'list'
require 'printValue'
local bit32 = require 'numberlua'.bit32

Format = {
  SingleTrack = 0,
  MultiTrackSynchronous = 1,
  MultiTrackAsynchronous = 2
}

Instrument = {
  -- Piano
  Acoustic_Grand = 0,
  Bright_Acoustic = 1,
  Electric_Grand = 2,
  Honky_Tonk = 3,
  Electric_Piano_1 = 4,
  Electric_Piano_2 = 5,
  Harpsichord = 6,
  Clav = 7,

  -- Chrome Percussion
  Celesta = 8,
  Glockenspiel = 9,
  Music_Box = 10,
  Vibraphone = 11,
  Marimba = 12,
  Xylophone = 13,
  Tubular_Bells = 14,
  Dulcimer = 15,

  -- Organ
  Drawbar_Organ = 16,
  Percussive_Organ = 17,
  Rock_Organ = 18,
  Church_Organ = 19,
  Reed_Organ = 20,
  Accoridan = 21,
  Harmonica = 22,
  Tango_Accordian = 23,

  -- Guitar
  Acoustic_Guitar_Nylon = 24,
  Acoustic_Guitar_Steel = 25,
  Electric_Guitar_Jazz = 26,
  Electric_Guitar_Clean = 27,
  Electric_Guitar_Muted = 28,
  Overdriven_Guitar = 29,
  Distortion_Guitar = 30,
  Guitar_Harmonics = 31,

  -- Bass
  Acoustic_Bass = 32,
  Electric_Bassfinger = 33,
  Electric_Basspick = 34,
  Fretless_Bass = 35,
  Slap_Bass_1 = 36,
  Slap_Bass_2 = 37,
  Synth_Bass_1 = 38,
  Synth_Bass_2 = 39,

  -- Strings
  Violin = 40,
  Viola = 41,
  Cello = 42,
  Contrabass = 43,
  Tremolo_Strings = 44,
  Pizzicato_Strings = 45,
  Orchestral_Strings = 46,
  Timpani = 47,

  -- Ensemble
  String_Ensemble_1 = 48,
  String_Ensemble_2 = 49,
  SynthStrings_1 = 50,
  SynthStrings_2 = 51,
  Choir_Aahs = 52,
  Voice_Oohs = 53,
  Synth_Voice = 54,
  Orchestra_Hit = 55,

  -- Brass
  Trumpet = 56,
  Trombone = 57,
  Tuba = 58,
  Muted_Trumpet = 59,
  French_Horn = 60,
  Brass_Section = 61,
  SynthBrass_1 = 62,
  SynthBrass_2 = 63,

  -- Reed
  Soprano_Sax = 64,
  Alto_Sax = 65,
  Tenor_Sax = 66,
  Baritone_Sax = 67,
  Oboe = 68,
  English_Horn = 69,
  Bassoon = 70,
  Clarinet = 71,

  -- Pipe
  Piccolo = 72,
  Flute = 73,
  Recorder = 74,
  Pan_Flute = 75,
  Blown_Bottle = 76,
  Skakuhachi = 77,
  Whistle = 78,
  Ocarina = 79,

  -- Synth Lead
  Lead_1_Square = 80,
  Lead_2_Sawtooth = 81,
  Lead_3_Calliope = 82,
  Lead_4_Chiff = 83,
  Lead_5_Charang = 84,
  Lead_6_Voice = 85,
  Lead_7_Fifths = 86,
  Lead_8_Bass_Lead = 87,

  -- Synth Pad
  Pad_1_New_Age = 88,
  Pad_2_Warm = 89,
  Pad_3_Polysynth = 90,
  Pad_4_Choir = 91,
  Pad_5_Bowed = 92,
  Pad_6_Metallic = 93,
  Pad_7_Halo = 94,
  Pad_8_Sweep = 95,

  -- Synth Effects
  FX_1_Rain = 96,
  FX_2_Soundtrack = 97,
  FX_3_Crystal = 98,
  FX_4_Atmosphere = 99,
  FX_5_Brightness = 100,
  FX_6_Goblins = 101,
  FX_7_Echoes = 102,
  FX_8_Scifi = 103,

  -- Ethnic
  Sitar = 104,
  Banjo = 105,
  Shamisen = 106,
  Koto = 107,
  Kalimba = 108,
  Bagpipe = 109,
  Fiddle = 110,
  Shanai = 111,

  -- Percussive
  Tinkle_Bell = 112,
  Agogo = 113,
  Steel_Drums = 114,
  Woodblock = 115,
  Taiko_Drum = 116,
  Melodic_Tom = 117,
  Synth_Drum = 118,
  Reverse_Cymbal = 119,

  -- Sound Effects
  Guitar_Fret_Noise = 120,
  Breath_Noise = 121,
  Seashore = 122,
  Bird_Tweet = 123,
  Telephone_Ring = 124,
  Helicopter = 125,
  Applause = 126,
  Gunshot = 127
}

--------------------------------------------------------------------------------

local function writeUInt32be(file, i)
  file:write(
    string.char(
      bit32.rshift(i, 24) % 256,
      bit32.rshift(i, 16) % 256,
      bit32.rshift(i, 8) % 256,
      bit32.rshift(i, 0) % 256))
end

local function writeUInt16be(file, i)
  file:write(
    string.char(
      bit32.rshift(i, 8) % 256,
      bit32.rshift(i, 0) % 256))
end

local function writeUInt8be(file, i)
  file:write(
    string.char(
      bit32.rshift(i, 0) % 256))
end

--------------------------------------------------------------------------------

-- A midi event represents one of many commands a midi file can run. The Event
-- re is a union of all possible events.
-- Only regular events (i.e. not Meta events) are significant to the midi file
-- playback
class 'Event' {
  __init = function(self, timeDelta, channel)
    self.timeDelta = timeDelta
    self.channel = channel
  end;

  writeEventTime = function(self, file, timeDelta)
    if self.timeDelta > (0x7F * 0x7F * 0x7F) then
      writeUInt8be(file, bit32.bor(bit32.rshift(self.timeDelta, 21), 0x80))
    elseif self.timeDelta > (0x7F * 0x7F) then
      writeUInt8be(file, bit32.bor(bit32.rshift(self.timeDelta, 14), 0x80))
    elseif self.timeDelta > (0x7F) then
      writeUInt8be(file, bit32.bor(bit32.rshift(self.timeDelta, 7), 0x80))
    end
    writeUInt8be(file, bit32.band(timeDelta, 0x7F))
  end;

  write = function(self, file, context)
    self:writeEventTime(file, self.timeDelta)
    local commandByte = bit32.bor(self.command, self.channel)
    if commandByte ~= context.previousCommandByte or self.command == Event.Meta then
      writeUInt8be(file, commandByte)
      context.previousCommandByte = commandByte
    end
  end;
}

class 'NoteEndEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, noteNumber, velocity)
    self.Event.__init(self, timeDelta, channel)
    self.noteNumber = noteNumber
    self.velocity = velocity
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    writeUInt8be(file, self.noteNumber)
    writeUInt8be(file, self.velocity)
  end;

  command = 0x80;
}

class 'NoteBeginEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, noteNumber, velocity)
    self.Event.__init(self, timeDelta, channel)
    self.noteNumber = noteNumber
    self.velocity = velocity
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    writeUInt8be(file, self.noteNumber)
    writeUInt8be(file, self.velocity)
  end;

  command = 0x90;
}

class 'VelocityChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, noteNumber, velocity)
    self.Event.__init(self, timeDelta, channel)
    self.noteNumber = noteNumber
    self.velocity = velocity
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    writeUInt8be(file, event.noteNumber)
    writeUInt8be(file, event.velocity)
  end;

  command = 0xA0;
}

class 'ControllerChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, controllerNumber, velocity)
    self.Event.__init(self, timeDelta, channel)
    self.controllerNumber = controllerNumber
    self.velocity = velocity
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    writeUInt8be(file, event.controllerNumber)
    writeUInt8be(file, event.velocity)
  end;

  command = 0xB0;
}

class 'ProgramChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, newProgramNumber)
    self.Event.__init(self, timeDelta, channel)
    self.newProgramNumber = newProgramNumber
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    writeUInt8be(file, event.newProgramNumber)
  end;

  command = 0xC0;
}

class 'ChannelPressureChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, channelNumber)
    self.Event.__init(self, timeDelta, channel)
    self.channelNumber = channelNumber
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    writeUInt8be(file, event.channelNumber)
  end;

  command = 0xD0;
}

class 'PitchWheelChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, bottom, top)
    self.Event.__init(self, timeDelta, channel)
    self.bottom = bottom
    self.top = top
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    writeUInt8be(file, event.bottom)
    writeUInt8be(file, event.top)
  end;

  command = 0xE0;
}

class 'MetaEvent' : extends(Event) {
  __init = function(self, timeDelta, channel)
    self.Event.__init(self, timeDelta, channel)
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    writeUInt8be(file, event.command)
    writeUInt8be(file, event.length)
    for i=1, event.length do
      writeUInt8be(file, event.data[i])
    end
  end;

  command = 0xF;
}

class 'SetSequenceNumberEvent' : extends(MetaEvent) {
  metaCommand = 0x00;
}

class 'TextEvent' : extends(MetaEvent) {
  metaCommand = 0x01;
}

class 'CopywriteEvent' : extends(MetaEvent) {
  metaCommand = 0x02;
}

class 'SequnceNameEvent' : extends(MetaEvent) {
  metaCommand = 0x03;
}

class 'TrackInstrumentNameEvent' : extends(MetaEvent) {
  metaCommand = 0x04;
}

class 'LyricEvent' : extends(MetaEvent) {
  metaCommand = 0x05;
}

class 'MarkerEvent' : extends(MetaEvent) {
  metaCommand = 0x06;
}

class 'CueEvent' : extends(MetaEvent) {
  metaCommand = 0x07;
}

class 'PrefixAssignmentEvent' : extends(MetaEvent) {
  metaCommand = 0x20;
}

class 'EndOfTrackEvent' : extends(MetaEvent) {
  metaCommand = 0x2F;
}

class 'SetTempoEvent' : extends(MetaEvent) {
  metaCommand = 0x51;
}

class 'SMPTEOffsetEvent' : extends(MetaEvent) {
  metaCommand = 0x54;
}

class 'TimeSignatureEvent' : extends(MetaEvent) {
  metaCommand = 0x58;
}

class 'KeySignatureEvent' : extends(MetaEvent) {
  metaCommand = 0x59;
}

class 'SequencerSpecificEvent' : extends(MetaEvent) {
  metaCommand = 0x7F;
}

--------------------------------------------------------------------------------

class 'Track' {
  __init = function(self)
    self.events = list{}
  end;

  getTrackByteLength = function(self)
    local length = 0
    local previousCommandByte = 0
    for event in self.events:ivalues() do
      -- Time delta
      if event.timeDelta > (0x7f * 0x7f * 0x7f) then
        length = length + 4
      elseif event.timeDelta > (0x7f * 0x7f) then
        length = length + 3
      elseif event.timeDelta > (0x7f) then
        length = length + 2
      else
        length = length + 1
      end

      -- Command
      local commandByte = bit32.bor(event.command, event.channel)
      if commandByte ~= previousCommandByte or event.command == MetaEvent.command then
        length = length + 1
        previousCommandByte = commandByte
      end

      -- One data byte
      if event.command == ProgramChangeEvent.command then
      elseif event.command == ChannelPressureChangeEvent.command then
        length = length + 1
      -- Two data bytes
      elseif event.command == NoteEndEvent.command
             or event.command == NoteBeginEvent.command
             or event.command == VelocityChangeEvent.command
             or event.command == ControllerChangeEvent.command
             or event.command == PitchWheelChangeEvent.command then
        length = length + 2
      -- Variable data bytes
      elseif event.command == Meta.command then
        length = length + 2 + event.meta.length
      end
    end
    return length
  end;

  write = function(self, file)
    writeUInt8be(file, string.byte('M'))
    writeUInt8be(file, string.byte('T'))
    writeUInt8be(file, string.byte('r'))
    writeUInt8be(file, string.byte('k'))
    writeUInt32be(file, self:getTrackByteLength())
    local context = {previousCommandByte = 0}
    for event in self.events:ivalues() do
      event:write(file, context)
    end
  end;
}

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
local class = require 'lx/class'
local midi_io = require 'midi/io'

-- A midi event represents one of many commands a midi file can run. The Event
-- re is a union of all possible events.
-- Only regular events (i.e. not Meta events) are significant to the midi file
-- playback
local Event = class 'Event' {
  __init = function(self, timeDelta, channel)
    self.timeDelta = timeDelta
    self.channel = channel
  end;

  writeEventTime = function(self, file, timeDelta)
    if self.timeDelta > (0x7F * 0x7F * 0x7F) then
      midi_io.writeUInt8be(file, (self.timeDelta >> 21) | 0x80)
    elseif self.timeDelta > (0x7F * 0x7F) then
      midi_io.writeUInt8be(file, (self.timeDelta >> 14) | 0x80)
    elseif self.timeDelta > (0x7F) then
      midi_io.writeUInt8be(file, (self.timeDelta >> 7) | 0x80)
    end
    midi_io.writeUInt8be(file, timeDelta & 0x7F)
  end;

  write = function(self, file, context)
    self:writeEventTime(file, self.timeDelta)
    local commandByte = self.command | self.channel
    if commandByte ~= context.previousCommandByte
       or self.command == Event.Meta then
      midi_io.writeUInt8be(file, commandByte)
      context.previousCommandByte = commandByte
    end
  end;
}

local NoteEndEvent = class 'NoteEndEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, noteNumber, velocity)
    self.Event.__init(self, timeDelta, channel)
    self.noteNumber = noteNumber
    self.velocity = velocity
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, self.noteNumber)
    midi_io.writeUInt8be(file, self.velocity)
  end;

  command = 0x80;
}

local NoteBeginEvent = class 'NoteBeginEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, noteNumber, velocity)
    self.Event.__init(self, timeDelta, channel)
    self.noteNumber = noteNumber
    self.velocity = velocity
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, self.noteNumber)
    midi_io.writeUInt8be(file, self.velocity)
  end;

  command = 0x90;
}

local VelocityChangeEvent = class 'VelocityChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, noteNumber, velocity)
    self.Event.__init(self, timeDelta, channel)
    self.noteNumber = noteNumber
    self.velocity = velocity
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, event.noteNumber)
    midi_io.writeUInt8be(file, event.velocity)
  end;

  command = 0xA0;
}

local ControllerChangeEvent = class 'ControllerChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, controllerNumber, velocity)
    self.Event.__init(self, timeDelta, channel)
    self.controllerNumber = controllerNumber
    self.velocity = velocity
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, event.controllerNumber)
    midi_io.writeUInt8be(file, event.velocity)
  end;

  command = 0xB0;
}

local ProgramChangeEvent = class 'ProgramChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, newProgramNumber)
    self.Event.__init(self, timeDelta, channel)
    self.newProgramNumber = newProgramNumber
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, event.newProgramNumber)
  end;

  command = 0xC0;
}

local ChannelPressureChangeEvent = class 'ChannelPressureChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, channelNumber)
    self.Event.__init(self, timeDelta, channel)
    self.channelNumber = channelNumber
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, event.channelNumber)
  end;

  command = 0xD0;
}

local PitchWheelChangeEvent = class 'PitchWheelChangeEvent' : extends(Event) {
  __init = function(self, timeDelta, channel, bottom, top)
    self.Event.__init(self, timeDelta, channel)
    self.bottom = bottom
    self.top = top
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, event.bottom)
    midi_io.writeUInt8be(file, event.top)
  end;

  command = 0xE0;
}

local MetaEvent = class 'MetaEvent' : extends(Event) {
  __init = function(self, timeDelta, channel)
    self.Event.__init(self, timeDelta, channel)
  end;

  write = function(self, file, context)
    self.Event.write(self, file, context)
    midi_io.writeUInt8be(file, event.command)
    midi_io.writeUInt8be(file, event.length)
    for i=1, event.length do
      midi_io.writeUInt8be(file, event.data[i])
    end
  end;

  command = 0xF;
}

local SetSequenceNumberEvent = class 'SetSequenceNumberEvent' : extends(MetaEvent) {
  metaCommand = 0x00;
}

local TextEvent = class 'TextEvent' : extends(MetaEvent) {
  metaCommand = 0x01;
}

local CopywriteEvent = class 'CopywriteEvent' : extends(MetaEvent) {
  metaCommand = 0x02;
}

local SequnceNameEvent = class 'SequnceNameEvent' : extends(MetaEvent) {
  metaCommand = 0x03;
}

local TrackInstrumentNameEvent = class 'TrackInstrumentNameEvent' : extends(MetaEvent) {
  metaCommand = 0x04;
}

local LyricEvent = class 'LyricEvent' : extends(MetaEvent) {
  metaCommand = 0x05;
}

local MarkerEvent = class 'MarkerEvent' : extends(MetaEvent) {
  metaCommand = 0x06;
}

local CueEvent = class 'CueEvent' : extends(MetaEvent) {
  metaCommand = 0x07;
}

local PrefixAssignmentEvent = class 'PrefixAssignmentEvent' : extends(MetaEvent) {
  metaCommand = 0x20;
}

local EndOfTrackEvent = class 'EndOfTrackEvent' : extends(MetaEvent) {
  metaCommand = 0x2F;
}

local SetTempoEvent = class 'SetTempoEvent' : extends(MetaEvent) {
  metaCommand = 0x51;
}

local SMPTEOffsetEvent = class 'SMPTEOffsetEvent' : extends(MetaEvent) {
  metaCommand = 0x54;
}

local TimeSignatureEvent = class 'TimeSignatureEvent' : extends(MetaEvent) {
  metaCommand = 0x58;
}

local KeySignatureEvent = class 'KeySignatureEvent' : extends(MetaEvent) {
  metaCommand = 0x59;
}

local SequencerSpecificEvent = class 'SequencerSpecificEvent' : extends(MetaEvent) {
  metaCommand = 0x7F;
}

return {
  Event=Event,
  NoteEndEvent=NoteEndEvent,
  NoteBeginEvent=NoteBeginEvent,
  VelocityChangeEvent=VelocityChangeEvent,
  ControllerChangeEvent=ControllerChangeEvent,
  ProgramChangeEvent=ProgramChangeEvent,
  ChannelPressureChangeEvent=ChannelPressureChangeEvent,
  PitchWheelChangeEvent=PitchWheelChangeEvent,
  MetaEvent=MetaEvent,
  SetSequenceNumberEvent=SetSequenceNumberEvent,
  TextEvent=TextEvent,
  CopywriteEvent=CopywriteEvent,
  SequnceNameEvent=SequnceNameEvent,
  TrackInstrumentNameEvent=TrackInstrumentNameEvent,
  LyricEvent=LyricEvent,
  MarkerEvent=MarkerEvent,
  CueEvent=CueEvent,
  PrefixAssignmentEvent=PrefixAssignmentEvent,
  EndOfTrackEvent=EndOfTrackEvent,
  SetTempoEvent=SetTempoEvent,
  SMPTEOffsetEvent=SMPTEOffsetEvent,
  TimeSignatureEvent=TimeSignatureEvent,
  KeySignatureEvent=KeySignatureEvent,
  SequencerSpecificEvent=SequencerSpecificEvent,
}
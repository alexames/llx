
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
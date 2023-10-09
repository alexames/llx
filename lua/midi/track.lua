require 'class'

local track = class 'Track' {
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

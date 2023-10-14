require 'strict'

local class = require 'lx/class'
local list = require 'lx/list'
local midi_io = require 'midi/io'
local events = require 'midi/events'

local Track = class 'Track' {
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
      local commandByte = event.command | event.channel
      if commandByte ~= previousCommandByte or event.command == MetaEvent.command then
        length = length + 1
        previousCommandByte = commandByte
      end

      -- One data byte
      if event.command == events.ProgramChangeEvent.command then
      elseif event.command == events.ChannelPressureChangeEvent.command then
        length = length + 1
      -- Two data bytes
      elseif event.command == events.NoteEndEvent.command
             or event.command == events.NoteBeginEvent.command
             or event.command == events.VelocityChangeEvent.command
             or event.command == events.ControllerChangeEvent.command
             or event.command == events.PitchWheelChangeEvent.command then
        length = length + 2
      -- Variable data bytes
      elseif event.command == Meta.command then
        length = length + 2 + event.meta.length
      end
    end
    return length
  end;

  write = function(self, file)
    file:write('MTrk')
    midi_io.writeUInt32be(file, self:getTrackByteLength())
    local context = {previousCommandByte = 0}
    for event in self.events:ivalues() do
      event:write(file, context)
    end
  end;
}

return Track
local unit = require 'llx.unit'
local llx = require 'llx'
local export = require 'llx.export'

local Config = export.Config
local Schema = llx.Schema
local Number = llx.Number
local String = llx.String
local Boolean = llx.Boolean

_ENV = unit.create_test_env(_ENV)

local function make_settings()
  return Config 'Settings' {
    volume = {
      type = Number, default = 0.5,
      minimum = 0, maximum = 1, ui_hint = 'slider',
    },
    fullscreen = {
      type = Boolean, default = false, ui_hint = 'checkbox',
    },
    name = {
      type = String, default = 'player', ui_hint = 'textbox',
    },
  }
end

describe('export.Config', function()
  describe('declaration', function()
    it('creates a Config with default values', function()
      local cfg = make_settings()
      expect(cfg.volume).to.be_equal_to(0.5)
      expect(cfg.fullscreen).to.be_equal_to(false)
      expect(cfg.name).to.be_equal_to('player')
    end)

    it('exposes title via :title()', function()
      expect(make_settings():title()).to.be_equal_to('Settings')
    end)

    it('rejects a bad default at declaration time', function()
      expect(function()
        Config 'Bad' {
          x = { type = Number, default = 'not a number' },
        }
      end).to.throw()
    end)

    it('requires a type in the schema', function()
      expect(function()
        Config 'NoType' {
          a = { default = 1 },
        }
      end).to.throw()
    end)

    it('rejects non-table field declarations', function()
      expect(function()
        Config 'Bad' { a = 42 }
      end).to.throw()
    end)

    it('accepts pre-built Schema instances', function()
      local cfg = Config 'WithSchema' {
        volume = Schema {
          type = Number, default = 0.5,
          minimum = 0, maximum = 1, ui_hint = 'slider',
        },
      }
      expect(cfg.volume).to.be_equal_to(0.5)
      cfg.volume = 0.9
      expect(cfg.volume).to.be_equal_to(0.9)
    end)
  end)

  describe('introspection', function()
    it(':fields() yields (name, schema)', function()
      local cfg = make_settings()
      local seen = {}
      for name, schema in cfg:fields() do
        seen[name] = schema
      end
      expect(seen.volume.type).to.be_equal_to(Number)
      expect(seen.volume.minimum).to.be_equal_to(0)
      expect(seen.volume.maximum).to.be_equal_to(1)
      expect(seen.volume.ui_hint).to.be_equal_to('slider')
      expect(seen.fullscreen.ui_hint).to.be_equal_to('checkbox')
    end)

    it(':get_schema returns the schema for a field', function()
      local cfg = make_settings()
      expect(cfg:get_schema('volume').ui_hint).to.be_equal_to('slider')
      expect(cfg:get_schema('volume').default).to.be_equal_to(0.5)
    end)

    it(':get_schema returns nil for unknown fields', function()
      local cfg = make_settings()
      expect(cfg:get_schema('does_not_exist')).to.be_nil()
    end)

    it('the schema is a real Schema (matches_schema works on it)', function()
      local cfg = make_settings()
      local schema = cfg:get_schema('volume')
      expect(llx.matches_schema(schema, 0.5)).to.be_true()
    end)

    it('supports pairs() over current values', function()
      local cfg = make_settings()
      local seen = {}
      for k, v in pairs(cfg) do seen[k] = v end
      expect(seen.volume).to.be_equal_to(0.5)
      expect(seen.fullscreen).to.be_equal_to(false)
      expect(seen.name).to.be_equal_to('player')
    end)
  end)

  describe('assignment', function()
    it('accepts values that match the schema', function()
      local cfg = make_settings()
      cfg.volume = 0.8
      expect(cfg.volume).to.be_equal_to(0.8)
    end)

    it('rejects values of the wrong type', function()
      local cfg = make_settings()
      expect(function() cfg.volume = 'loud' end).to.throw()
    end)

    it('rejects values outside the declared range', function()
      local cfg = make_settings()
      expect(function() cfg.volume = 2 end).to.throw()
    end)

    it('rejects assignment to unknown fields', function()
      local cfg = make_settings()
      expect(function() cfg.unknown = 1 end).to.throw()
    end)

    it('rejects reads of unknown fields', function()
      local cfg = make_settings()
      expect(function() return cfg.unknown end).to.throw()
    end)
  end)

  describe('live reads through closures', function()
    it('functions that close over the config see updates', function()
      local cfg = make_settings()
      local function current_volume() return cfg.volume end
      expect(current_volume()).to.be_equal_to(0.5)
      cfg.volume = 0.2
      expect(current_volume()).to.be_equal_to(0.2)
    end)
  end)

  describe('on_change', function()
    it('fires per-field observers when the value changes', function()
      local cfg = make_settings()
      local seen
      cfg:on_change('volume', function(v, previous)
        seen = { value = v, previous = previous }
      end)
      cfg.volume = 0.9
      expect(seen.value).to.be_equal_to(0.9)
      expect(seen.previous).to.be_equal_to(0.5)
    end)

    it('does not fire when assigning the same value', function()
      local cfg = make_settings()
      local count = 0
      cfg:on_change('volume', function() count = count + 1 end)
      cfg.volume = 0.5
      expect(count).to.be_equal_to(0)
    end)

    it('fires global observers for any field', function()
      local cfg = make_settings()
      local events = {}
      cfg:on_change(function(name, value)
        events[#events + 1] = { name = name, value = value }
      end)
      cfg.volume = 0.7
      cfg.fullscreen = true
      expect(#events).to.be_equal_to(2)
    end)

    it('rejects observers on unknown fields', function()
      local cfg = make_settings()
      expect(function()
        cfg:on_change('unknown', function() end)
      end).to.throw()
    end)
  end)

  describe('serialize / deserialize', function()
    it('round-trips current values', function()
      local cfg = make_settings()
      cfg.volume = 0.25
      cfg.name = 'alex'
      local data = cfg:serialize()
      expect(data.volume).to.be_equal_to(0.25)
      expect(data.name).to.be_equal_to('alex')

      local cfg2 = make_settings()
      cfg2:deserialize(data)
      expect(cfg2.volume).to.be_equal_to(0.25)
      expect(cfg2.name).to.be_equal_to('alex')
    end)

    it('ignores unknown keys in the input', function()
      local cfg = make_settings()
      cfg:deserialize({ volume = 0.1, made_up = 99 })
      expect(cfg.volume).to.be_equal_to(0.1)
    end)

    it('validates loaded values', function()
      local cfg = make_settings()
      expect(function()
        cfg:deserialize({ volume = 'bad' })
      end).to.throw()
    end)
  end)

  describe('reset', function()
    it('restores defaults and notifies observers', function()
      local cfg = make_settings()
      local fired_for
      cfg:on_change('volume', function(v) fired_for = v end)
      cfg.volume = 0.9
      cfg:reset()
      expect(cfg.volume).to.be_equal_to(0.5)
      expect(fired_for).to.be_equal_to(0.5)
    end)
  end)
end)

if llx.main_file() then
  unit.run_unit_tests()
end

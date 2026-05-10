-- examples/01_classes.lua
-- Class definition, inheritance, properties, and conversions.

local llx = require 'llx'
local class = llx.class

-- Single inheritance with __init.
local Animal = class 'Animal' {
  __init = function(self, name)
    self._name = name
  end,
  get_name = function(self) return self._name end,
}

local Dog = class 'Dog' : extends(Animal) {
  __init = function(self, name, breed)
    self.Animal.__init(self, name)  -- call the named superclass init
    self._breed = breed
  end,
  speak = function(self)
    return self:get_name() .. ' says woof!'
  end,
}

local rex = Dog('Rex', 'Labrador')
print(rex:speak())             --> Rex says woof!
print(rex:get_name())          --> Rex

-- Properties: getter/setter pairs that look like fields.
local property = require 'llx.property'.property

local Rectangle = class 'Rectangle' {
  __init = function(self, w, h)
    self._w = w
    self._h = h
  end,
  ['width' | property] = {
    get = function(self) return self._w end,
    set = function(self, v) self._w = v end,
  },
  ['area' | property] = {
    get = function(self) return self._w * self._h end,
  },  -- read-only: no setter
}

local r = Rectangle(10, 5)
print(r.width)      --> 10
r.width = 7
print(r.area)       --> 35
-- print(r.area = 99) -- would raise: no setter

-- Conversion: every named class gets a `to_<Name>(value)` function
-- that looks for `__to_<Name>` on the source object's metatable.
local Celsius = class 'Celsius' {
  __init = function(self, v) self.value = v end,
}
local Fahrenheit = class 'Fahrenheit' {
  __init = function(self, v) self.value = v end,
  __to_Celsius = function(self)
    return Celsius((self.value - 32) * 5 / 9)
  end,
}
local boiling = Celsius.to_Celsius(Fahrenheit(212))
print(boiling.value)  --> 100

-- isinstance walks the inheritance chain.
local isinstance = llx.isinstance
print(isinstance(rex, Dog))    --> true
print(isinstance(rex, Animal)) --> true

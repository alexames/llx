-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

local class = require 'llx/src/class'
local decorator = require 'llx/src/decorator'

--- Treat a getter/setter pair on a table as a field.
local Property = class.class 'Property' : extends(decorator.Decorator) {
  decorate = function(self, class, name, value)
    return class.__properties, name, value
  end,
}
local property = Property()

return {
  Property=Property,
  property=property,
}
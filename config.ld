-- LDoc configuration for llx
-- Run with: ldoc .

project = 'llx'
title = 'llx - Lua Extension Library'
description = [[
A comprehensive Lua utility library providing extensions and utilities for Lua development.
Includes object-oriented class system, functional programming utilities, type checking,
schema validation, exception handling, and more.
]]

-- Source files
file = {
  '.',
  exclude = {
    'tests',
    'bytecode',
    'experimental',
  }
}

-- Output directory
dir = 'docs'

-- Use markdown for descriptions
format = 'markdown'

-- Sort alphabetically
sort = true

-- Include all documented items
all = true

-- Template style
style = 'ldoc.css'
template = nil

-- Custom CSS (optional)
custom_css = nil

-- Package display name
package = 'llx'

-- One file per module
one = false

-- Show source code links
no_return_or_parms = false
no_summary = false

-- Merge modules into single pages
merge = false

-- Manual pages (optional)
-- readme = 'README.md'

-- Module ordering (optional)
-- topics = {'readme.md'}

-- Custom tags
custom_tags = {
  {'example', title = 'Example', format = nil},
  {'usage', title = 'Usage', format = nil},
}

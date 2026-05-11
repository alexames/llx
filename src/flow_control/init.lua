-- Copyright 2024 Alexander Ames <Alexander.Ames@gmail.com>

-- Aggregator for the flow_control submodules. Exposes try and catch
-- directly so `llx.flow_control.try {...}` works without requiring
-- the individual files. switchcase is not included here because it
-- intentionally registers globals (switch, case, type_switch,
-- default); require it explicitly when needed.
return require 'llx.flatten_submodules' {
  require 'llx.flow_control.trycatch',
  require 'llx.flow_control.catch',
}

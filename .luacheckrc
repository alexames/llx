std = "lua54"

-- Source modules use `local _ENV, _M = llx.environment.create_module_environment()`
-- which replaces _ENV with a custom module table. After this, all unqualified names
-- resolve against the new environment. `allow_defined` permits these module-level
-- definitions and cross-references without flagging them as globals.
allow_defined = true

max_line_length = false

ignore = {
  "_M",   -- module return table, assigned but consumed by require()
  "_ENV", -- reassigned as part of the module pattern
  "113",  -- accessing undefined variable (cross-module refs via _ENV)
  "131",  -- unused global variable (module exports consumed externally)
  "143",  -- accessing undefined field of global (custom extensions like string.split)
  "211",  -- unused variable (module-pattern locals like `local Foo = require(...)`)
  "212",  -- unused argument (interface/callback signatures)
  "213",  -- unused loop variable
  "311",  -- value assigned to variable is unused
  "411",  -- variable was previously defined
  "421",  -- shadowing definition of variable
  "431",  -- shadowing upvalue (common in nested scopes)
  "512",  -- loop is executed at most once (intentional test patterns)
  "542",  -- empty if branch (intentional guard patterns)
}

exclude_files = {
  "lua_modules",
  "docs",
}

files["tests"] = {
  -- Test files use `_ENV = unit.create_test_env(_ENV)` which injects these globals.
  globals = {
    "describe",
    "it",
    "expect",
    "before_each",
    "after_each",
    "before_all",
    "after_all",
    "unit",
  },
}

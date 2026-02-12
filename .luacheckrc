std = "lua54"

-- Source modules use `local _ENV, _M = llx.environment.create_module_environment()`
-- which replaces _ENV with a custom module table. After this, all unqualified names
-- resolve against the new environment. `allow_defined` permits these module-level
-- definitions and cross-references without flagging them as globals.
allow_defined = true

ignore = {
  "_M",   -- module return table, assigned but consumed by require()
  "_ENV", -- reassigned as part of the module pattern
  "113",  -- accessing undefined variable (cross-module refs via _ENV)
  "131",  -- unused global variable (module exports consumed externally)
  "211",  -- unused variable (module-pattern locals like `local Foo = require(...)`)
  "212",  -- unused argument (interface/callback signatures)
  "213",  -- unused loop variable
  "431",  -- shadowing upvalue (common in nested scopes)
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

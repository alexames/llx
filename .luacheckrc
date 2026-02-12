std = "lua54"

-- Source modules use `local _ENV, _M = llx.environment.create_module_environment()`
-- which replaces _ENV with a custom module table. After this, all unqualified names
-- resolve against the new environment. `allow_defined_top = true` permits these
-- module-level definitions without flagging them as globals.
allow_defined_top = true

-- _M is the module return table, always assigned but consumed by require().
-- _ENV is reassigned as part of the module pattern.
ignore = { "_M", "_ENV" }

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

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
  "1",    -- unused/undefined warnings (module pattern causes false positives)
  "2",    -- unused variable/argument/value warnings
  "3",    -- value assigned to variable is unused
  "4",    -- shadowing and variable redefinition
  "5",    -- code quality hints (empty branches, single-iteration loops)
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

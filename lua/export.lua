export_config = {}
export_config.types = {}
export_config.index = 0
export_config.ui_hint = {}

function export_config.ui_hint()
end

function create_export_type(name, t, mt, default)
  t = t or {}
  mt = mt or {}
  t.name = name
  t.meta = mt
  t.meta.default = default
  function mt.__call(t, v)
    export_config.index = export_config.index + 1
    return { type = t, value = v, index = export_config.index }
  end
  setmetatable(t, mt)
  export_config.types[t] = t
  _G[name] = t
end

function export(t)
  sorted = {}
  for name, variable_data in pairs(t) do
    value = variable_data.value or variable_data.type.meta.default
    _G[name] = value
    table.insert(sorted, {
      name = name,
      type = variable_data.type,
      value = value,
      index = variable_data.index,
    })
  end
  table.sort(sorted, function(a, b) return a.index < b.index end)
  for i, variable in ipairs(sorted) do
    print(variable.type.name .. ' ' .. variable.name .. ' = ' .. tostring(variable.value))
  end
end

--------------------------------------------------------------------------------

create_export_type("bool", {}, {}, false, checkbox)
create_export_type("number", {}, {}, 0, textbox)
create_export_type("string", string, {}, "", textbox)

--------------------------------------------------------------------------------

-- TODO: add a way to represent the range or set of possible options, and
--       possibly a hint for how to display them
-- Range w/min and max, and snap
-- Dropdown box with values
-- Radio box with values
-- text entry
-- color picker
-- date
-- asset picker
-- file picker
-- checkbox
-- texture

export {
  foo = number(100);
  bar = string("test");
  baz = bool(true);
  quux = bool();
  quaz = bool();
  bork = number();
}

print("testing foo:", foo)
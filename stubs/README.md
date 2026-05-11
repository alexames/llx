# llx type stubs for sumneko/luals

These files provide [LuaCATS](https://luals.github.io/wiki/annotations/)
type annotations for the llx public API. They're used by the
[Lua language server](https://luals.github.io/) to give your editor
type-aware completion, hover docs, and lightweight type checking
for code that uses llx.

The stubs are not loaded at runtime. They exist purely to feed the
language server.

## What's covered

- `llx.lua` — the main module, with all flattened top-level fields
  and named-submodule pointers. Also declares `llx.ClassDefiner`,
  `llx.Schema`, and `llx.NamedTuple` for use by other stubs.
- `llx/collections.lua` — Deque, Counter, OrderedDict, DefaultDict,
  Heap (full method signatures, constructor overloads).
- `llx/result.lua` — Result and Option.
- `llx/functional.lua` — iterators, transforms, reductions,
  combinators.
- `llx/mathx.lua` — statistical and numeric utilities.
- `llx/bisect.lua` — binary search and insort.
- `llx/types.lua` — List and Set with full method signatures and
  operator overloads (`|`, `-`, `&`, `~` for Set; `..`, `*`, `<<`,
  `>>` for List).
- `llx/tuple.lua` — Tuple (immutable, lexicographic).
- `llx/string_view.lua` — StringView with forwarded string methods.
- `llx/exceptions.lua` — full hierarchy: Exception, ExceptionGroup,
  IndexError, InvalidArgumentException, InvalidArgumentTypeException,
  NotImplementedException, RuntimeError, SchemaException and its
  three subclasses, TypeError, ValueException.

### Class-system caveat

llx classes are defined via `class 'Name' { ... }` with decorator
keys like `['name' | property] = { ... }` and metaprogrammed
metamethod inheritance. luals cannot read these constructs:
inside a `class 'Name' { ... }` block the body table will be typed
as `{[any]: any}` and the resulting class shape won't be inferred.

For consumers of llx-defined classes, the hand-written stubs here
give full completion and hover. For authors defining their own
classes, you'll get the best results by writing a `---@class
Name : SuperClass` declaration alongside the runtime definition.

Submodules with no dedicated stub file: `class`, `unit`,
`flow_control`, `schema`, `bytecode`, `decorator`, `property`,
`hash`, `hash_table`, `enum`, `proxy`, `debug`, `tracing`, `cache`,
`coroutine`, `truthy`, `repr`, `tostringf`, `tointeger`,
`check_arguments`, `signature`, `method`. Their public names work
from auto-completion via `llx.foo` lookups, but the named-submodule
namespaces are typed as `any`. Contributions welcome.

## Setup

### Per-project (.luarc.json)

In the root of any project that uses llx, create or edit
`.luarc.json`:

```json
{
  "workspace.library": [
    "/absolute/path/to/llx/stubs"
  ],
  "runtime.version": "Lua 5.4",
  "diagnostics.globals": []
}
```

Replace `/absolute/path/to/llx` with the actual location.

### VS Code (settings.json)

Add to your workspace `.vscode/settings.json`:

```json
{
  "Lua.workspace.library": [
    "/absolute/path/to/llx/stubs"
  ],
  "Lua.runtime.version": "Lua 5.4"
}
```

### Via luarocks install (future)

When llx is installed via `luarocks install llx`, the stubs ship
with the rock, but luals does not currently auto-discover them.
Until it does, point at the stubs/ directory in your local checkout
or in `~/.luarocks/share/lua/5.4/llx/stubs` (if present).

## Verifying

With the stubs wired up, in any file that does
`local llx = require 'llx'`:

- Hover over `llx.Deque` should show "llx.Deque".
- Hover over `llx.functional.map` should show its signature.
- Auto-complete after `local q = llx.Deque{}; q:` should suggest
  `push_left`, `pop_right`, `peek_right`, etc.

## Adding stubs for a new module

1. Create `stubs/llx/<modname>.lua` with `---@meta` at the top.
2. Declare a class for the module's namespace and methods/fields.
3. Reference the class from `stubs/llx.lua` via the `---@field`
   on the main `llx` class.

# llx Examples

Each example here is a self-contained, runnable Lua script that
demonstrates one area of llx in real use. They're meant to be read
top-to-bottom and copied into your own code.

## Running

After installing llx with `luarocks make --local`, run any example
directly:

```sh
lua examples/01_classes.lua
```

If your `lua` defaults to a Lua version older than 5.4, use
`lua5.4` explicitly. If module resolution fails, prepend the
luarocks path:

```sh
eval "$(luarocks-5.4 path)" && lua5.4 examples/01_classes.lua
```

## Examples

| File                          | Demonstrates                              |
|-------------------------------|-------------------------------------------|
| `01_classes.lua`              | Class definition, inheritance, properties |
| `02_functional.lua`           | Iterators, transforms, reductions         |
| `03_schema.lua`               | Runtime type checks and schema validation |
| `04_exceptions.lua`           | Structured exceptions, try/catch          |
| `05_unit_testing.lua`         | BDD-style tests with mocks                |
| `06_collections.lua`          | Deque, Counter, OrderedDict, DefaultDict, Heap |
| `07_result_option.lua`        | Result and Option for non-exceptional flow |
| `08_namedtuple_bisect.lua`    | Immutable named tuples and binary search   |

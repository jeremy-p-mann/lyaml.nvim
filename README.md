# lyaml.nvim

A [Neovim](https://neovim.io/) plugin that bundles the
[lyaml](https://github.com/gvvaughan/lyaml) bindings together with a vendored
copy of [libyaml](https://github.com/yaml/libyaml). It exposes the same Lua API
as the upstream `lyaml` module while providing a seamless installation flow for
modern Neovim setups.

The plugin targets Neovim 0.10 or later and supports the
`vim.pack.add` package manager API introduced alongside `vim.system`.

## Features

- Ships the original lyaml Lua modules unchanged.
- Builds the native lyaml binding on-demand with a single `:LyamlBuild`
  command.
- Automatically attempts to compile the native module the first time it is
  required.
- Includes a vendored copy of libyaml so there is no external dependency
  required at build time.
- Bundles Lua 5.1 headers so the native module can be built without
  system-wide Lua development packages.

## Installation

### Using `vim.pack.add`

```lua
vim.pack.add('lyaml.nvim')
```

The first call to `require('lyaml')` will automatically compile the native
module if it is missing. If you prefer to build eagerly, run `:LyamlBuild`
after installing the plugin.

### Other plugin managers

Any plugin manager that places the repository inside `runtimepath` (for example
[lazy.nvim](https://github.com/folke/lazy.nvim)) will work as long as the plugin
is loaded before you attempt to `require('lyaml')`.

## Usage

Once the plugin is installed and the native module has been built, you can use
the API exactly like upstream:

```lua
local lyaml = require('lyaml')
local stream = [[
- hello
- world
]]

print(vim.inspect(lyaml.load(stream)))
```

The module also registers itself under `package.loaded['yaml']` to preserve
compatibility with existing code that expects `require('yaml')`.

## Building

The plugin exposes a `:LyamlBuild` command which compiles the native module in
the current environment. The command accepts a bang (`:LyamlBuild!`) to force a
rebuild even if a compiled module is already present.

The build helper honours the `CC` environment variable or `vim.g.lyaml_cc` if
you need to use a custom compiler. If the plugin
cannot locate `lua.h` automatically, set `vim.g.lyaml_lua_include` (or the
`LUA_INCDIR` environment variable) to the directory that
contains the Lua headers.

## License

The original lyaml sources are licensed under the MIT license. The vendored
libyaml sources retain their original MIT license found in
[`third_party/libyaml/License`](third_party/libyaml/License) and the Lua 5.1
headers ship with their MIT license in
[`third_party/lua51/COPYRIGHT`](third_party/lua51/COPYRIGHT).

local M = {}

local uv = vim.loop

local function plugin_root()
  local source = debug.getinfo(1, 'S').source
  if not source:find('^@') then
    error('unable to resolve plugin root for lyaml.nvim')
  end
  local dir = vim.fs.dirname(source:sub(2))
  dir = vim.fs.dirname(dir)
  dir = vim.fs.dirname(dir)
  return dir
end

local function join(...)
  return vim.fs.joinpath(...)
end

local function system(cmd, opts)
  local result = vim.system(cmd, opts):wait()
  return result.code, result.stdout, result.stderr
end

local function ensure_dir(path)
  if uv.fs_stat(path) then
    return
  end
  assert(uv.fs_mkdir(path, 493))
end

local function detect_output()
  local sysname = uv.os_uname().sysname
  if sysname:match('Windows') then
    return '.dll', { '-shared' }, {}
  elseif sysname == 'Darwin' then
    return '.dylib', { '-bundle', '-undefined', 'dynamic_lookup' }, {}
  else
    return '.so', { '-shared' }, { '-fPIC' }
  end
end

local function source_files(root)
  local files = {}
  local function add(dir, names)
    for _, name in ipairs(names) do
      table.insert(files, join(root, dir, name))
    end
  end

  add('third_party/libyaml/src', {
    'api.c',
    'dumper.c',
    'emitter.c',
    'loader.c',
    'parser.c',
    'reader.c',
    'scanner.c',
    'writer.c',
  })

  add('src/lyaml', {
    'emitter.c',
    'parser.c',
    'scanner.c',
    'yaml.c',
  })

  return files
end

local function detect_lua_includes(opts, root)
  local dirs = {}
  local seen = {}

  local function push(dir)
    if not dir or dir == '' then
      return
    end
    dir = vim.fs.normalize(dir)
    if seen[dir] then
      return
    end
    if uv.fs_stat(join(dir, 'lua.h')) then
      seen[dir] = true
      table.insert(dirs, dir)
    end
  end

  if root then
    push(join(root, "third_party/lua51/include"))
  end

  if opts and opts.lua_include then
    push(opts.lua_include)
  end

  push(vim.g.lyaml_lua_include)
  push(vim.env.LUA_INCDIR)
  push(vim.env.LUA_INCLUDE_DIR)

  if vim.env.LUA_DIR then
    push(join(vim.env.LUA_DIR, 'include'))
  end

  for entry in package.cpath:gmatch('[^;]+') do
    local prefix = entry:gsub('%?.*', '')
    if prefix ~= '' then
      push(prefix)
      push(join(prefix, '..'))
      push(join(prefix, '../include'))
      push(join(prefix, '../../include'))
    end
  end

  local sysname = uv.os_uname().sysname
  local defaults = {
    '/usr/include',
    '/usr/include/lua5.1',
    '/usr/include/lua',
    '/usr/include/luajit-2.1',
    '/usr/local/include',
    '/usr/local/include/lua5.1',
    '/usr/local/include/lua',
    '/usr/local/include/luajit-2.1',
  }

  if sysname == 'Darwin' then
    vim.list_extend(defaults, {
      '/opt/homebrew/include',
      '/opt/homebrew/include/luajit-2.1',
      '/opt/homebrew/opt/luajit/include',
      '/opt/homebrew/opt/luajit/include/luajit-2.1',
      '/usr/local/opt/luajit/include',
      '/usr/local/opt/luajit/include/luajit-2.1',
    })
  elseif sysname:match('Windows') then
    vim.list_extend(defaults, {
      'C:/lua/include',
      'C:/Program Files/Lua/5.1/include',
      'C:/Program Files (x86)/Lua/5.1/include',
    })
  end

  for _, dir in ipairs(defaults) do
    push(dir)
  end

  if #dirs == 0 then
    error('lyaml.nvim: could not locate lua.h. Set vim.g.lyaml_lua_include or LUA_INCDIR.')
  end

  return dirs
end

function M.build(opts)
  opts = opts or {}

  local root = plugin_root()
  local ext, shared_flags, extra_cflags = detect_output()
  local cc = opts.cc or vim.g.lyaml_cc or vim.env.CC or 'cc'
  local lua_includes = detect_lua_includes(opts, root)
  local includes = {
    '-I' .. join(root, 'third_party/libyaml/include'),
    '-I' .. join(root, 'third_party/libyaml/src'),
    '-I' .. join(root, 'src/lyaml'),
  }

  for _, dir in ipairs(lua_includes) do
    table.insert(includes, '-I' .. dir)
  end

  local cflags = {
    '-O2',
    '-std=c99',
  }
  vim.list_extend(cflags, extra_cflags)
  if opts.cflags then
    vim.list_extend(cflags, opts.cflags)
  end

  local output_dir = join(root, 'lua/lyaml')
  ensure_dir(output_dir)
  local output = join(output_dir, 'core' .. ext)

  if not opts.force then
    local stat = uv.fs_stat(output)
    if stat then
      return output
    end
  end

  local sources = source_files(root)
  local defines = {
    '-DYAML_VERSION_MAJOR=0',
    '-DYAML_VERSION_MINOR=2',
    '-DYAML_VERSION_PATCH=5',
    '-DYAML_VERSION_STRING="0.2.5"',
  }

  if not uv.os_uname().sysname:match('Windows') then
    table.insert(defines, '-D_GNU_SOURCE')
  else
    table.insert(defines, '-D_CRT_SECURE_NO_WARNINGS')
  end

  if opts.defines then
    vim.list_extend(defines, opts.defines)
  end

  local cmd = { cc }
  vim.list_extend(cmd, cflags)
  vim.list_extend(cmd, shared_flags)
  table.insert(cmd, '-o')
  table.insert(cmd, output)
  vim.list_extend(cmd, includes)
  for _, define in ipairs(defines) do
    table.insert(cmd, define)
  end
  vim.list_extend(cmd, sources)

  if not opts.quiet then
    vim.notify('lyaml.nvim: building native module...', vim.log.levels.INFO)
  end

  local code, _, stderr = system(cmd, { text = true, cwd = root })

  if code ~= 0 then
    error(('lyaml.nvim: build failed:\n%s'):format(stderr))
  end

  return output
end

return M

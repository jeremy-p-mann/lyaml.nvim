vim.loader.enable()

local repo = assert(vim.env.LYAML_REPO, 'Missing LYAML_REPO environment variable')
if not repo:match('^file://') then
  repo = 'file://' .. repo
end

local spec = {
  {
    name = 'lyaml.nvim',
    src = repo,
    version = vim.env.LYAML_REF,
  },
}

vim.pack.add(spec, { load = true, confirm = false })

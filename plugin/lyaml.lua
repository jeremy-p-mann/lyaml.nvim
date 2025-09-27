if vim.g.loaded_lyaml then
  return
end
vim.g.loaded_lyaml = true

local function notify(msg, level)
  if vim.notify then
    vim.notify(msg, level)
  else
    vim.api.nvim_echo({ { msg, level == vim.log.levels.ERROR and 'ErrorMsg' or 'None' } }, true, {})
  end
end

vim.api.nvim_create_user_command('LyamlBuild', function(opts)
  local ok, builder = pcall(require, 'lyaml.build')
  if not ok then
    notify('lyaml.nvim: failed to load build helper: ' .. builder, vim.log.levels.ERROR)
    return
  end

  local success, result = pcall(builder.build, { force = opts.bang })
  if not success then
    notify(result, vim.log.levels.ERROR)
    return
  end

  notify('lyaml.nvim: native module available at ' .. result, vim.log.levels.INFO)
end, {
  bang = true,
  desc = 'Build the lyaml native module',
})

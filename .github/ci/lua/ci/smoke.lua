local M = {}

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(message or string.format('expected %q but got %q', expected, actual), 2)
  end
end

local function ensure(condition, message)
  if not condition then
    error(message or 'assertion failed', 2)
  end
end

function M.run()
  local lyaml = require('lyaml')

  local stream = table.concat({ '- alpha', '- beta' }, '\n')
  local data = assert(lyaml.load(stream), 'failed to load inline yaml stream')
  assert_eq(data[1], 'alpha', 'unexpected first element from stream load')
  assert_eq(data[2], 'beta', 'unexpected second element from stream load')

  local tmp = vim.fs.joinpath(vim.fn.stdpath('state'), 'ci-sample.yaml')
  vim.fn.mkdir(vim.fs.dirname(tmp), 'p')
  vim.fn.writefile({ 'greeting: hello' }, tmp)
  local lines = vim.fn.readfile(tmp)
  ensure(#lines > 0, 'yaml file should not be empty')

  local parsed = assert(lyaml.load(table.concat(lines, '\n')), 'failed to load yaml file contents')
  assert_eq(parsed.greeting, 'hello', 'yaml file contents parsed incorrectly')

  vim.pack.update({ 'lyaml.nvim' }, { force = true })
end

return M

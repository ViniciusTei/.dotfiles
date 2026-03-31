-- [[ Basic Autocommands ]]
-- See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('vinicius-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Atualiza o buffer automaticamente se o arquivo for alterado externamente
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold' }, {
  pattern = '*',
  callback = function()
    if vim.fn.getbufvar(vim.fn.bufnr(), '&modifiable') == 1 then
      vim.cmd 'checktime'
    end
  end,
})

-- Exibe uma mensagem se o arquivo foi alterado
vim.api.nvim_create_autocmd('FileChangedShellPost', {
  pattern = '*',
  callback = function()
    local filename = vim.fn.expand '%:p'
    local datetime = os.date '%Y-%m-%d %H:%M:%S'
    local message = string.format("'%s' foi recarregado em %s", filename, datetime)
    vim.notify(message, vim.log.levels.INFO, { title = 'Arquivo atualizado' })
  end,
})

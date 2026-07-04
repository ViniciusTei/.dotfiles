return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require 'lint'
    lint.linters_by_ft = {
      javascript = { 'eslint_d' },
      typescript = { 'eslint_d' },
      javascriptreact = { 'eslint_d' },
      typescriptreact = { 'eslint_d' },
    }

    local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
    vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
      group = lint_augroup,
      callback = function()
        local linters = lint.linters_by_ft[vim.bo.filetype] or {}
        local available = vim.tbl_filter(function(l)
          return vim.fn.executable(l) == 1
        end, linters)
        if #available > 0 then
          lint.try_lint(available)
        end
      end,
    })

    vim.keymap.set('n', '<leader>tl', function()
      lint.try_lint()
    end, { desc = '[T]rigger [L]inting for a file' })
  end,
}

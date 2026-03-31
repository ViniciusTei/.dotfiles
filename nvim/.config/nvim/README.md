# vinicius.nvim

Personal Neovim configuration built on top of [kickstart.nvim](https://github.com/nvim-kickstart/kickstart.nvim), organized under `lua/vinicius/`.

## Structure

```
nvim/.config/nvim/
├── init.lua                    # Entry point — loads lua/vinicius/
└── lua/
    └── vinicius/
        ├── init.lua            # Leader keys, lazy.nvim bootstrap, requires core modules
        ├── options.lua         # All vim.opt.* settings
        ├── keymaps.lua         # Global keymaps (window nav, search, etc.)
        ├── autocmds.lua        # Global autocommands (yank highlight, file reload)
        ├── health.lua          # :checkhealth vinicius.nvim
        └── plugins/
            ├── ui.lua          # tokyonight · mini.nvim (ai, surround, statusline) · web-devicons
            ├── telescope.lua   # Fuzzy finder + extensions
            ├── lsp.lua         # LSP stack: lspconfig · mason · blink.cmp · LuaSnip · fidget · lazydev
            ├── treesitter.lua  # Syntax highlighting and parsing
            ├── formatting.lua  # conform.nvim
            ├── linting.lua     # nvim-lint
            ├── git.lua         # gitsigns (signs + keymaps)
            ├── debug.lua       # nvim-dap + dap-ui + mason-dap + dap-go
            ├── editing.lua     # autopairs · autotag · guess-indent · todo-comments · which-key
            ├── typescript.lua  # typescript-tools.nvim
            ├── copilot.lua     # GitHub Copilot
            └── indent.lua      # indent-blankline
```

local b0 = {
  '                                                    ',
  ' ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ',
  ' ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ',
  ' ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ',
  ' ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ',
  ' ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ',
  ' ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ',
  '                                                    ',
}
local b1 = {
  '                                                       ',
  ' ██╗   ██╗██╗███╗   ██╗██╗ ██████╗██╗██╗   ██╗███████╗ ',
  ' ██║   ██║██║████╗  ██║██║██╔════╝██║██║   ██║██╔════╝ ',
  ' ██║   ██║██║██╔██╗ ██║██║██║     ██║██║   ██║███████╗ ',
  ' ╚██╗ ██╔╝██║██║╚██╗██║██║██║     ██║██║   ██║╚════██║ ',
  '  ╚████╔╝ ██║██║ ╚████║██║╚██████╗██║╚██████╔╝███████║ ',
  '   ╚═══╝  ╚═╝╚═╝  ╚═══╝╚═╝ ╚═════╝╚═╝ ╚═════╝ ╚══════╝ ',
  '                                                       ',
}
return {
  { -- Colorscheme
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup {
        styles = {
          comments = { italic = false },
        },
      }
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  { -- Collection of various small independent plugins/modules
    'echasnovski/mini.nvim',
    config = function()
      -- Better Around/Inside textobjects
      require('mini.ai').setup { n_lines = 500 }

      -- Add/delete/replace surroundings (brackets, quotes, etc.)
      require('mini.surround').setup()

      -- Simple and easy statusline
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },

  { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },

  {
    'goolord/alpha-nvim',
    config = function()
      local alpha = require 'alpha'
      local dashboard = require 'alpha.themes.dashboard'
      dashboard.section.header.val = b1
      -- Menu (Shortcuts)
      dashboard.section.buttons.val = {
        dashboard.button('e', '  New file', ':ene <BAR> startinsert<CR>'),
        dashboard.button('f', '  Find file', ':Telescope find_files<CR>'),
        dashboard.button('g', '󱈇  Grep', ':Telescope live_grep<CR>'),
        dashboard.button('s', '  Settings', ':e $MYVIMRC<CR>'),
        dashboard.button('q', '  Quit', ':qa<CR>'),
      }
      alpha.setup(dashboard.config)
    end,
  },
}

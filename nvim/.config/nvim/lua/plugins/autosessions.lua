require('auto-session').setup {
  log_level = vim.log.levels.ERROR,
  auto_session_suppress_dirs = { "~/", "~/Documents", "~/Downloads", "/" },
  auto_session_use_git_branch = false,
  auto_session_root_dir = "~/.config/nvim/sessions/",
  auto_session_enabled = true,
  auto_save_enabled = true,
  auto_restore_enabled = true,
  auto_session_enable_last_session = true,
  auto_session_last_session_dir = "~/.config/nvim/sessions/",
  cwd_change_handling = {
    post_cwd_changed_hook = function() -- example refreshing the lualine status line _after_ the cwd changes
      require("lualine").refresh()     -- refresh lualine so the new session name is displayed in the status bar
    end,
  },
}

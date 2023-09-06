require('auto-session').setup {
  log_level = vim.log.levels.ERROR,
  auto_session_suppress_dirs = { "~/", "~/Documentos", "~/Downloads", "/"},
  auto_session_use_git_branch = false,
  auto_session_root_dir = vim.fn.stdpath('data').."/sessions/",
  auto_session_enabled = true,
  auto_save_enabled = true,
  auto_restore_enabled = true,
  auto_session_enable_last_session = true,
  auto_session_last_session_dir = vim.fn.stdpath('data').."/sessions/",
}

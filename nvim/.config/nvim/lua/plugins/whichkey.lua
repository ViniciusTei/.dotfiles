local wk = require('which-key')

-- TODO - Add more keybinds, and organize some of the existing ones.
wk.register({
  g = { name = "Go to" },
  m = { name = "Format" },
  o = { name = "Open" },
  c = { name = "[LSP] Code" },
  w = { name = "[LSP] Workspace" },
  r = { name = "[LSP] Renam" },
  d = { name = "[LSP] Document" },
  s = { name = "Search" },
  p = { name = "[Git] Preview" },
}, { prefix = '<leader>' })

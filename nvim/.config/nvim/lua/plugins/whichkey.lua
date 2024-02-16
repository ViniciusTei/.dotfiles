local wk = require('which-key')

-- TODO - Add more keybinds, and organize some of the existing ones.
wk.register({
  g = { name = "Go to" },
  m = { name = "Format" },
  o = { name = "Open" },
}, { prefix = '<leader>' })

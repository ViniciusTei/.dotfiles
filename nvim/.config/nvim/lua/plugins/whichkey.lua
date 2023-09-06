local wk = require('which-key')

-- TODO - Add more keybinds, and organize some of the existing ones.
wk.register({
  g = {
    name = "Go to"
  },
  o = {
    name = "Open"
  },
}, { prefix = '<leader>' })

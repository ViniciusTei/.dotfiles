# CLAUDE.md

## Repository Overview

Personal dotfiles managed with **GNU Stow**. The directory structure mirrors target locations so stow can symlink them: e.g., `nvim/.config/nvim/` → `~/.config/nvim/`.

## Installation & Applying Changes

```bash
# Apply all symlinks
stow .

# Full system setup (installs deps, compiles polybar, installs neovim, etc.)
./scripts/.scripts/setup.sh

# One-liner remote install (deprecated we are no longer uing Github for hosting)
curl -o- https://raw.githubusercontent.com/ViniciusTei/.dotfiles/master/install.sh | bash
```

After editing any config, changes take effect immediately via symlinks — no re-stow needed unless adding new files.

## Architecture

### Stow Package Layout

Each top-level directory is a stow package. Files inside follow the path they should appear at relative to `$HOME`:

| Directory | Target |
|-----------|--------|
| `nvim/.config/nvim/` | `~/.config/nvim/` |
| `i3/.config/i3/` | `~/.config/i3/` |
| `polybar/.config/polybar/` | `~/.config/polybar/` |
| `rofi/.config/rofi/` | `~/.config/rofi/` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `scripts/.bash_aliases` | `~/.bash_aliases` |
| `scripts/.scripts/` | `~/.scripts/` |

### Neovim Config (`nvim/.config/nvim/`)

Based on kickstart.nvim, organized as:

- `init.lua` — bootstraps lazy.nvim and requires `vinicius.*` modules
- `lua/vinicius/lazy/` — one file per plugin spec (e.g., `lsp.lua`, `telescope.lua`, `harpoon.lua`)
- `lua/vinicius/set.lua` — vim options
- `lua/vinicius/remap.lua` — global keymaps (leader = Space)
- `lua/vinicius/lazy_init.lua` — lazy.nvim setup

LSP is configured via mason + lspconfig + blink.cmp. Formatting via conform.nvim, linting via nvim-lint. DAP configured for Go.

### Polybar (`polybar/.config/polybar/`)

- `config.ini` — all bar definitions and modules
- `launch-polybar.sh` — called by i3 on startup; iterates connected monitors and starts one bar per monitor. Includes a workaround for bottom-positioning with `override-redirect`.

### Scripts (`scripts/.scripts/`)

Key scripts relevant when making changes:

- `bash.sh` — sourced by `.bashrc`; defines the git-aware prompt and an `fzf`-enhanced `cd` override
- `battery-notify.sh` — daemon; run at i3 startup
- `monitor-hotplug.sh` — invoked by udev rule; handles display connect/disconnect (runs as root then re-invokes as user)
- `btctl.sh` — bluetooth wrapper (see `scripts/btctl.md` for usage)
- `aireview.sh` / `gitmerge.sh` — AI-assisted git workflow tools

### i3 Config (`i3/.config/i3/config`)

- Mod key: `Super` (Mod4)
- vim-style navigation: `hjkl`
- Calls `launch-polybar.sh` on startup
- Wallpaper set via `feh`
- Keyboard layout toggled US/BR via `layout.sh`
- Screenshot bindings via `screenshot.sh`

## Theme

- **Neovim:** TokyoNight
- **Tmux/Polybar:** Catppuccin
- **Font:** FiraCode Nerd Font (installed to `~/.local/share/fonts/`)

# Neovim Config — Claude Context

## Location & Dotfiles

- **Config root:** `~/.dotfiles/.config/nvim/` (symlinked to `~/.config/nvim/`)
- **GitHub remote:** `https://github.com/gheatherington/neovim_config`
- **Plugin data:** `~/.local/share/nvim/lazy/`
- **Plugin lockfile:** `~/.dotfiles/.config/nvim/lazy-lock.json`

---

## Directory Structure

```
lua/gavin/
  core/
    init.lua          — requires options + keymaps
    options.lua       — all vim.opt settings
    keymaps.lua       — leader key + core keymaps
  lazy.lua            — lazy.nvim bootstrap and setup
  plugins/
    init.lua          — base plugins (plenary, vim-tmux-navigator)
    lsp/
      lspconfig.lua   — LSP keymaps, server configs, diagnostic signs
      mason.lua       — mason + mason-lspconfig + tool installer
    <plugin>.lua      — one file per plugin
```

**Load chain:** `init.lua` → `gavin.core` (options, keymaps) → `gavin.lazy` (lazy.nvim setup, imports all of `gavin.plugins` and `gavin.plugins.lsp`)

---

## Plugin Manager

**lazy.nvim** (stable branch). To add a plugin, create a new file under `lua/gavin/plugins/` returning a plugin spec table. Run `:Lazy sync` in Neovim to install/remove. Run `:Lazy update` to update all plugins.

### Installed Plugins (from lazy-lock.json)

| Plugin | Branch |
|---|---|
| Comment.nvim | master |
| LuaSnip | master |
| alpha-nvim | main |
| auto-session | main |
| cmp-buffer / cmp-nvim-lsp / cmp-path / cmp_luasnip | main/master |
| conform.nvim | master |
| dressing.nvim | master |
| friendly-snippets | main |
| **fzf-lua** | main |
| gitsigns.nvim | main |
| indent-blankline.nvim | master |
| lazy.nvim | main |
| lazygit.nvim | main |
| lspkind.nvim | master |
| lualine.nvim | master |
| mason.nvim + mason-lspconfig + mason-tool-installer | main |
| neodev.nvim | main |
| noice.nvim + nui.nvim + nvim-notify | main/master |
| nvim-autopairs | master |
| nvim-cmp | main |
| nvim-colorizer.lua | master |
| nvim-lint | master |
| nvim-lsp-file-operations | master |
| nvim-lspconfig | master |
| nvim-surround | main |
| nvim-tree.lua | master |
| nvim-treesitter + nvim-ts-autotag + nvim-ts-context-commentstring | master/main |
| nvim-ufo + promise-async | main |
| nvim-web-devicons | master |
| plenary.nvim | master |
| render-markdown.nvim | main |
| substitute.nvim | main |
| tokyonight.nvim | main |
| trouble.nvim | main |
| **tv.nvim** | main |
| vim-maximizer | master |
| vim-tmux-navigator | master |
| which-key.nvim | main |

**Note:** telescope.nvim and telescope-fzf-native.nvim have been fully removed.

---

## Picker Stack — IMPORTANT

This config uses **two pickers** with distinct responsibilities. Do not merge them or replace one with the other.

| Tool | Repo | Responsibility |
|---|---|---|
| **tv.nvim** | `alexpasmantier/tv.nvim` | File finding, text/grep search, recent files, channel browsing |
| **fzf-lua** | `ibhagwan/fzf-lua` | ALL LSP pickers: references, definitions, implementations, type defs, diagnostics |

**Telescope has been fully removed.** Do not add it back or reference `Telescope` commands anywhere.

**tv binary** is at `/opt/homebrew/bin/tv` (version 0.15.3+). tv.nvim is a thin Lua wrapper around it.

### tv.nvim Known Issue: vim-tmux-navigator conflict
`<C-j>` and `<C-k>` inside tv terminal buffers were being intercepted by vim-tmux-navigator. Fixed in `tv.lua` with a `TermOpen` autocmd that sends raw bytes (`\x0a`/`\x0b`) directly via `nvim_chan_send` to the terminal channel when the buffer name matches `/tv`.

---

## LSP Configuration

### Servers

| Server | Config Method | Notes |
|---|---|---|
| `bashls` | `vim.lsp.config` + `vim.lsp.enable` | cmd: `bash-language-server start`, ft: bash, sh |
| `ruff` | `vim.lsp.config` + `vim.lsp.enable` | Python linter-as-LSP; also runs as nvim-lint linter (potential duplicate diagnostics) |
| `pyright` | `vim.lsp.config` + `vim.lsp.enable` | Auto-detects `.venv/bin/python` in cwd at startup; falls back to system python. Runs `diagnosticMode = "workspace"` |
| `lua_ls` | `vim.lsp.config` only | **`vim.lsp.enable("lua_ls")` is missing** — handled by mason-lspconfig auto-setup fallback |
| html, cssls, tailwindcss, svelte, graphql, emmet_ls, prismals | mason-lspconfig `ensure_installed` | Auto-setup, no explicit config overrides |

### LSP Keymaps (buffer-local, set on LspAttach)

| Key | Command | Description |
|---|---|---|
| `gR` | `FzfLua lsp_references` | Show references |
| `gD` | `vim.lsp.buf.declaration` | Go to declaration (single jump, built-in correct) |
| `gd` | `FzfLua lsp_definitions` | Show definitions |
| `gi` | `FzfLua lsp_implementations` | Show implementations |
| `gt` | `FzfLua lsp_typedefs` | Show type definitions |
| `gF` | `FzfLua lsp_finder` | Combined finder (refs + defs + impls in one picker) |
| `<leader>ca` | `vim.lsp.buf.code_action` | Code actions (n + v) |
| `<leader>rn` | `vim.lsp.buf.rename` | Smart rename |
| `<leader>D` | `FzfLua diagnostics_document` | Buffer diagnostics |
| `<leader>d` | `vim.diagnostic.open_float` | Line diagnostics float |
| `[d` / `]d` | `vim.diagnostic.goto_prev/next` | Navigate diagnostics |
| `K` | `vim.lsp.buf.hover` | Hover documentation |
| `<leader>rs` | `:LspRestart<CR>` | Restart LSP |

### Mason-Installed Tools

**Formatters** (via conform.nvim): `prettier` (JS/TS/CSS/HTML/JSON/YAML/MD/GraphQL/Svelte/Liquid), `stylua` (Lua), `isort` + `black` (Python)

**Linters** (via nvim-lint): `eslint_d` (JS/TS/Svelte), `ruff` (Python)

**Installed but NOT wired up:** `beautysh` (shell formatter), `shellcheck` (shell linter) — both installed via mason-tool-installer but have no entries in conform or nvim-lint.

### Format/Lint Keymaps

| Key | Action |
|---|---|
| `<leader>mp` | Format file or visual range (conform.nvim) |
| `<leader>l` | Trigger lint on current file (nvim-lint) |

Format-on-save is enabled (async=false, timeout=1000ms, lsp_fallback=true).

---

## Completion (nvim-cmp)

**Snippet engine:** LuaSnip + friendly-snippets (VSCode-style)

**Sources:** nvim_lsp → luasnip → buffer → path

| Key | Action |
|---|---|
| `<C-k>` / `<C-j>` | Previous / next item |
| `<C-b>` / `<C-f>` | Scroll docs up / down |
| `<C-Space>` | Trigger completion |
| `<C-e>` | Abort completion |
| `<CR>` | Confirm (only explicitly selected items) |

---

## Core Options (options.lua)

- **Leader:** `<Space>`
- **Indent:** 2 spaces, expandtab, autoindent
- **Numbers:** relative + absolute current line
- **Clipboard:** `unnamedplus` (system clipboard)
- **Splits:** right + below
- **Search:** ignorecase + smartcase
- **No swapfile, no line wrap**
- **termguicolors:** true
- **signcolumn:** always shown

---

## Core Keymaps (keymaps.lua)

| Key | Action |
|---|---|
| `jk` (insert) | Exit insert mode |
| `<leader>nh` | Clear search highlights |
| `<leader>+` / `<leader>-` | Increment / decrement number |
| `<leader>sv/sh/se/sx` | Split vertical / horizontal / equalize / close |
| `<leader>to/tx/tn/tp/tf` | Tab: new / close / next / prev / current buf in tab |

---

## Plugin Keymaps Reference

### File Exploration
| Key | Plugin | Action |
|---|---|---|
| `<leader>ee` | nvim-tree | Toggle file explorer |
| `<leader>ef` | nvim-tree | Focus explorer on current file |
| `<leader>ec` | nvim-tree | Collapse explorer |
| `<leader>er` | nvim-tree | Refresh explorer |

### Fuzzy Finding (tv.nvim)
| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fs` | Live grep / text search |
| `<leader>fc` | Search word under cursor |
| `<leader>fr` | Recent files |
| `<leader>tv` | Open channel selector |

**tv in-picker keys:** `<CR>` open, `<C-q>` quickfix, `<C-s>` split, `<C-v>` vsplit, `<C-y>` clipboard

### Git
| Key | Plugin | Action |
|---|---|---|
| `<leader>lg` | lazygit | Open lazygit TUI |
| `]h` / `[h` | gitsigns | Next / prev hunk |
| `<leader>hs/hr` | gitsigns | Stage / reset hunk (n+v) |
| `<leader>hS/hR` | gitsigns | Stage / reset buffer |
| `<leader>hu` | gitsigns | Undo stage hunk |
| `<leader>hp` | gitsigns | Preview hunk |
| `<leader>hb/hB` | gitsigns | Blame line / toggle blame |
| `<leader>hd/hD` | gitsigns | Diff this / diff vs last commit |

### Diagnostics & Trouble
| Key | Plugin | Action |
|---|---|---|
| `<leader>xw` | trouble | Workspace diagnostics |
| `<leader>xd` | trouble | Document diagnostics |
| `<leader>xq` | trouble | Quickfix list |
| `<leader>xl` | trouble | Location list |

### Folding (nvim-ufo)
| Key | Action |
|---|---|
| `zR` | Open all folds |
| `zM` | Close all folds |
| `za` | Toggle fold |
| `zK` | Peek fold (or LSP hover if not on fold) |

### Editing Utilities
| Key | Plugin | Action |
|---|---|---|
| `s{motion}` | substitute | Substitute with motion |
| `ss` | substitute | Substitute line |
| `S` | substitute | Substitute to end of line |
| `ys{m}{c}` / `ds{c}` / `cs{o}{n}` | surround | Add / delete / change surround |
| `<leader>sm` | vim-maximizer | Maximize / restore split |
| `<leader>a` | alpha | Show dashboard |
| `<leader>wr/ws` | auto-session | Restore / save session |

---

## Colorscheme

**tokyonight.nvim** — `night` style with heavy customization:
- `transparent = true` (background, sidebars, floats)
- Custom deep-blue palette (`#011628` bg, `#CBE0F0` fg, `#0A64AC` search)

---

## UI Stack

| Plugin | Purpose |
|---|---|
| noice.nvim | Replaces cmdline, messages, popupmenu with floats |
| dressing.nvim | Improves `vim.ui.input` and `vim.ui.select` |
| nvim-notify | Notification backend (used by noice) |
| lualine.nvim | **Winbar** (top of window, not bottom statusline) — `laststatus=0` |
| which-key.nvim | Keymap popup after 500ms timeout |
| indent-blankline | `┊` indent guides |
| nvim-colorizer | Inline color swatches for hex/RGB/CSS |
| render-markdown | Visual markdown rendering in buffer |

---

## Treesitter

Parsers installed: `json`, `javascript`, `typescript`, `tsx`, `yaml`, `html`, `css`, `prisma`, `python`, `markdown`, `markdown_inline`, `svelte`, `graphql`, `bash`, `lua`, `vim`, `dockerfile`, `gitignore`, `query`, `vimdoc`, `c`

Features: highlighting, indentation, autotag (`nvim-ts-autotag`), incremental selection (`<C-space>` expand, `<bs>` shrink).

Treesitter-based folding is **disabled** (commented out). Folding is handled entirely by nvim-ufo.

---

## Known Issues / TODOs

1. **`vim.lsp.enable("lua_ls")` is missing** in lspconfig.lua — lua_ls relies on mason-lspconfig auto-setup fallback. Worth adding explicitly for consistency with the other servers.

2. **ruff runs twice** — as an LSP server (`vim.lsp.enable("ruff")`) AND as a linter in nvim-lint. This can produce duplicate diagnostics for Python files.

3. **beautysh and shellcheck are installed but unwired** — both in mason-tool-installer but not configured in conform or nvim-lint respectively.

4. **Python path detection is startup-time only** — `get_python_path(vim.fn.getcwd())` runs once when Neovim starts, not per-buffer. Opening files in a different project won't pick up that project's venv.

# Neovim Config — Claude Context

## Workflow

After making any changes to this config, always commit and push to GitHub:
```bash
git add <files>
git commit -m "description of change"
git push
```
Remote: `https://github.com/gheatherington/neovim_config`

---

## Location & Dotfiles

- **Config root:** `~/.dotfiles/.config/nvim/` (symlinked to `~/.config/nvim/`)
- **GitHub remote:** `https://github.com/gheatherington/neovim_config`
- **Plugin data:** `~/.local/share/nvim/lazy/`
- **Plugin lockfile:** `~/.dotfiles/.config/nvim/lazy-lock.json`

---

## Directory Structure

```
codebook.toml         — codebook spell-checker config + word list (passed as globalConfigPath)
lua/gavin/
  core/
    init.lua          — requires options + keymaps
    options.lua       — all vim.opt settings
    keymaps.lua       — leader key + core keymaps
  lazy.lua            — lazy.nvim bootstrap and setup
  remote_python.lua   — basedpyright support for Python files on sshfs mounts (not a plugin spec)
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
| mason.nvim + mason-lspconfig (mason-org) + mason-tool-installer | main |
| lazydev.nvim | main |
| noice.nvim + nui.nvim + nvim-notify | main/master |
| nvim-autopairs | master |
| nvim-cmp | main |
| nvim-colorizer.lua (catgoose fork) | master |
| nvim-lint | master |
| nvim-lsp-file-operations | master |
| nvim-lspconfig | master |
| nvim-surround | main |
| nvim-tree.lua | master |
| nvim-treesitter + nvim-ts-autotag + nvim-ts-context-commentstring | master/main |
| nvim-ufo + promise-async | main |
| nvim-web-devicons | master |
| plenary.nvim | master |
| **oil.nvim** | master |
| render-markdown.nvim | main |
| **sshfs.nvim** | main |
| substitute.nvim | main |
| tokyonight.nvim | main |
| trouble.nvim | main |
| **tv.nvim** | main |
| vim-maximizer | master |
| vim-tmux-navigator | master |
| which-key.nvim | main |

**Note:** telescope.nvim, telescope-fzf-native.nvim, and distant.nvim have been fully removed.

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
| `ruff` | `vim.lsp.config` + `vim.lsp.enable` | Python linter-as-LSP; sole source of ruff diagnostics (not an nvim-lint linter) |
| `basedpyright` | `vim.lsp.config` + `vim.lsp.enable` | Replaced pyright. Resolves the interpreter per project root in `before_init`: `.venv`/`venv`/`.env` → `$VIRTUAL_ENV` → `python3` → `python`. `typeCheckingMode = "standard"`, `diagnosticMode = "openFilesOnly"`, inlay hints on. On sshfs mounts, see **Remote Python** below |
| `lua_ls` | `vim.lsp.config` + `vim.lsp.enable` | Lua API types for config/plugin editing come from lazydev.nvim |
| `harper_ls` | mason-lspconfig `ensure_installed` + `vim.lsp.config` | Spelling + grammar. **Comments only** in code; full text in markdown/gitcommit. `diagnosticSeverity = "information"` (default `hint` is too faint). `dialect = "Canadian"` (colour/centre, but -ize like American). Add a word to its dictionary via `<leader>ca` |
| `codebook` | mason-lspconfig `ensure_installed` + `vim.lsp.config` | Full-dictionary spell check of **string literals only** (`include_tags = ["string"]` in `codebook.toml`). Code filetypes only — `markdown`/`gitcommit`/`text` removed from lspconfig's defaults since harper owns prose |
| `typos_lsp` | mason-lspconfig `ensure_installed` | Known-misspelling list (not a dictionary), so near-zero false positives. Runs on **every filetype** and checks strings and identifiers too. Per-project ignores go in `typos.toml` / `_typos.toml` |
| html, cssls, tailwindcss, svelte, graphql, emmet_ls, prismals | mason-lspconfig `ensure_installed` | No explicit config; enabled by mason-lspconfig v2's `automatic_enable = true` |

**Global capabilities:** `vim.lsp.config("*", { capabilities = cmp_nvim_lsp.default_capabilities() })` in `lspconfig.lua` advertises nvim-cmp's completion capabilities (snippet/resolve support) to every server.

**Spell checking split** — three servers, one job each; Neovim's built-in `spell` stays off:

| Server | Checks | Method |
|---|---|---|
| harper | Comments, markdown, commit messages | Dictionary + **grammar**, Canadian |
| codebook | String literals only | Full dictionary (`en_us` + `en_gb`); skips hex colours, URLs, paths, UUIDs, hashes, words < 3 chars |
| typos | Everything, incl. identifiers at use sites and non-code files | Curated list of ~known misspellings only, so near-zero false positives |

harper can't check strings (harper#544, closed "not planned"); typos can't catch one-off typos (`Distanc`, `gmae`) — hence codebook. Built-in spell + spellwand.nvim was the runner-up (real `en_ca`), rejected for a young plugin with a multi-line-string position bug and per-language query maintenance.

**codebook gotchas:**
- **Config lives in `codebook.toml` at the repo root**, passed as `init_options.globalConfigPath`. A *project* `codebook.toml` is unreliable: codebook resolves it from its **process cwd**, not the LSP root (log showed `Project config: /private/tmp/codebook.toml`).
- Add words with the **"Add to global dictionary"** code action — it writes into the repo's `codebook.toml` (commit it). Plain "Add to dictionary" would create a `codebook.toml` in whatever the cwd is. codebook **rewrites the file and strips comments**, so keep explanations here, not in the TOML.
- **No `en_ca` dictionary** — `en_us` + `en_gb` together accept both `colour` and `color` in strings. Canadian spelling is only enforced in comments (harper).
- **Escape bug** ([codebook#306](https://github.com/blopker/codebook/issues/306)): `"\nworld"` is read as `nworld`. `ignore_patterns = ['\\[nrtbfv][A-Za-z]+']` suppresses it — an ignore pattern only skips a word if it covers the *whole* word, hence the `[A-Za-z]+`. Trade-off: a typo directly after `\n`/`\t` is caught by nothing (typos glues the escape on too).
- A common typo inside a string (e.g. `recieved`) is reported by both codebook and typos. Comment typos on typos' list are reported by both harper and typos.
- Grammar inside strings isn't checked by anything.
- `typos-lsp --version` doesn't exist and just blocks waiting on stdin (`codebook-lsp --version` is fine).

**Python diagnostics split:** basedpyright reports type errors only; ruff reports lint only. basedpyright's `reportUnusedImport`/`reportUnusedVariable`/`reportDeprecated` are set to `"none"` because ruff already covers them — leaving them on reported every unused import twice. `typeCheckingMode` is pinned to `"standard"` because basedpyright's default is stricter than pyright's and floods the buffer with "Type of X is unknown".

**`useLibraryCodeForTypes` is deliberately unset** — upstream discourages setting it, since it overrides per-project `pyproject.toml`. Default is already `true`.

**mason-lspconfig v2:** `setup_handlers()` and `automatic_installation` were removed upstream; `automatic_enable` defaults to `true`, so every installed server is `vim.lsp.enable()`'d automatically. It is set to `{ exclude = { "pyright" } }` here: pyright was replaced by basedpyright, and if its mason package lingers on disk automatic_enable would silently run both at once. Servers configured explicitly in `lspconfig.lua` are simply enabled twice (idempotent).

### Remote Python (files on sshfs mounts)

basedpyright runs locally and can't execute the remote interpreter (e.g. ARM Linux on a Pi), so remote-only libraries would all show `Import "x" could not be resolved`. `lua/gavin/remote_python.lua` fixes this:

- **Sync (`:RemotePySync [host]`, automatic on first Python file per host):** probes the remote's `python3` for its version and `site-packages`/`dist-packages` dirs, rsyncs only `.py`/`.pyi`/`py.typed` into `~/.cache/nvim/remote-python/<host>/root/<remote path>`, and creates **empty placeholder** files for `.so` modules (enough for import resolution; saves ~120 MB on qarm). Then `uv python install <version>` for a matching local interpreter. Writes `env.json` (`version`, `paths`, `python`) and runs `:lsp restart basedpyright`. Re-run `:RemotePySync` after installing packages on the remote.
- **`root_dir`:** normal basedpyright root markers, but never above the mount root — so a sibling package (e.g. `P1/Common`) resolves when you mount its parent. Mount the directory that contains *all* your project's packages.
- **`before_init`:** `remote_python.apply(config)` sets `basedpyright.analysis.extraPaths` to the mirror and returns the uv interpreter as `pythonPath` (so the target version matches the remote). Must **mutate** `config.settings` in place — the client already holds a reference to that table; reassigning it silently has no effect.
- SSH reuses sshfs.nvim's ControlMaster socket (`~/.ssh/sockets/%C`) with `BatchMode=yes`, so sync needs an active or recent mount on hosts that need a password.
- Uses the built-in `:lsp restart` (nvim 0.12), not `:LspRestart`, which only exists after nvim-lspconfig is loaded.
- ruff is unaffected: it never resolves imports.

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
| `[d` / `]d` | `vim.diagnostic.jump({ count = -1 / 1 })` | Navigate diagnostics |
| `K` | `vim.lsp.buf.hover` | Hover documentation |
| `<leader>ih` | `vim.lsp.inlay_hint.enable` | Toggle inlay hints (buffer-local) |
| `<leader>rs` | `:LspRestart<CR>` | Restart LSP |

### Mason-Installed Tools

**Formatters** (via conform.nvim): `prettier` (JS/TS/CSS/HTML/JSON/YAML/MD/GraphQL/Svelte/Liquid), `stylua` (Lua), `ruff_organize_imports` + `ruff_format` (Python), `beautysh` (sh/bash)

**Linters** (via nvim-lint): `eslint_d` (JS/TS/Svelte) only.

**Spell checkers** run as LSP servers, not nvim-lint linters: `harper_ls` + `codebook` + `typos_lsp` (see **Spell checking split** above).

`ruff` and `shellcheck` are deliberately NOT nvim-lint linters: ruff already runs as an LSP server, and `bash-language-server` runs shellcheck internally. Listing either here produced every diagnostic twice.

### Format/Lint Keymaps

| Key | Action |
|---|---|
| `<leader>mp` | Format file or visual range (conform.nvim) |
| `<leader>l` | Trigger lint on current file (nvim-lint) |

Format-on-save is enabled (`async = false`, `timeout_ms = 5000`, `lsp_format = "fallback"`).

**`timeout_ms` is one shared budget for the whole formatter chain, not per-formatter.** Python formerly chained `isort` (~100ms) and `black` (~150ms) and would intermittently blow a 1000ms ceiling. It now uses ruff for both steps (~8ms each, single binary, 8x faster overall); output was byte-identical to isort+black when measured, though ruff targets black compatibility rather than guaranteeing it. isort and black are no longer installed.

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
- **`inccommand = "split"`:** `:substitute` shows a live preview of the resulting lines in a split before you commit (the default, `nosplit`, only highlights matches inline)
- **No swapfile, no line wrap**
- **termguicolors:** true
- **signcolumn:** always shown

---

## Core Keymaps (keymaps.lua)

| Key | Action |
|---|---|
| `jk` (insert) | Exit insert mode |
| `<M-BS>` (insert) | Delete word backwards (Option+Delete) |
| `<leader>nh` | Clear search highlights |
| `<leader>tw` | Toggle line wrap |
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
| `-` | oil.nvim | Open oil in current directory |
| `<leader>Ro` | oil.nvim | Open remote SSH directory (prompts for user@host:/path) |

**oil.nvim in-buffer keys:** `<CR>` open, `-` up a directory, `<C-s>` vsplit, `<C-t>` new tab, `<C-p>` preview, `<C-r>` refresh, `g.` toggle hidden, `g?` help. Note: `<C-h>` and `<C-l>` disabled (vim-tmux-navigator conflict).

### Remote / SSH (sshfs.nvim)
| Key | Command | Action |
|---|---|---|
| `<leader>mm` | `:SSHConnect` | Mount SSH host (fzf-lua picker from `~/.ssh/config`) |
| `<leader>mu` | `:SSHDisconnect` | Unmount current session |
| `<leader>mU` | `:SSHDisconnectAll` | Unmount all sessions |
| `<leader>mf` | `:SSHFiles` | Find files on mount (fzf-lua) |
| `<leader>mg` | `:SSHGrep` | Search file contents on mount |
| `<leader>mF` | `:SSHLiveFind` | Live find — streams remote find results |
| `<leader>mG` | `:SSHLiveGrep` | Live grep — streams remote rg results |
| `<leader>md` | — | `tcd` to mount directory (silent cwd change) |
| `<leader>me` | — | Open file explorer on mount |
| `<leader>mo` | — | Run arbitrary command on mount |
| `<leader>mt` | `:SSHTerminal` | Open remote shell |
| `<leader>mc` | `:SSHConfig` | Edit `~/.ssh/config` |
| `<leader>mr` | `:SSHReload` | Reload SSH config |
| `<leader>ms` | — | Save a copy of the current buffer to a local path (prompted; default `~/Downloads/`, then last-used dir). Trailing `/` = directory, keeps filename. Confirms overwrite. Custom — defined in `sshfs.lua` `config` |

Mounts at `~/mnt/<host>`. Auto-unmounts on Neovim exit. Requires macFUSE + sshfs (`brew install --cask macfuse && brew install gromgit/fuse/sshfs-mac`). Once mounted, all local tools (tv.nvim, fzf-lua, nvim-tree, LSP) work against remote files normally. For Python, remote-only libraries resolve via a synced package mirror — `:RemotePySync [host]` refreshes it (see **Remote Python** under LSP Configuration).

**Launching straight into a remote (`nvs`, defined in `~/.zshrc` — not in this repo):**
```bash
nvs                 # tv ssh-hosts picker (same channel as the `sshf` alias) → nvim +"SSHConnect <host>"
nvs docker-server   # skip the picker
```
`nvs` reuses `~/.config/television/cable/ssh-hosts.toml` but overrides the channel's `enter` (which runs `ssh`) with `-k 'enter="confirm_selection"'` so tv prints the host instead. Note tv 0.15 `-k` syntax is `key="action"`, not `action="key"`. The mount-location prompt (home / root / custom) always appears — sshfs.nvim ignores a `host:/path` argument there. auto-session has `auto_restore = false`, so launch directory doesn't matter.

**Manual mount/unmount (shell fallback):**
```bash
# Mount
mkdir -p ~/mnt/<host> && sshfs <host>:/ ~/mnt/<host> -o reconnect,compression=yes,ConnectTimeout=5,ServerAliveInterval=15,ServerAliveCountMax=3,cache=yes
# Unmount (graceful)
umount ~/mnt/<host>
# Unmount (force — use when graceful fails)
diskutil unmount force ~/mnt/<host>
```

**tv channel:** `tv sshfs-mounts` — browse active mounts, `Ctrl-u` unmount, `Ctrl-f` force unmount. Channel at `~/.config/television/cable/sshfs-mounts.toml`.

**sshfs.nvim config notes** (in `lua/gavin/plugins/sshfs.lua`):
- `hooks.on_mount.auto_change_to_dir = true`: mounting runs `tcd <mount>` so tv.nvim / nvim-tree (cwd-based) target the remote immediately; unmount `tcd`s back to the previous dir.
- `ui.local_picker` is the current key (not `ui.file_picker` — deprecated)
- Plugin defaults include three invalid macOS option names (`dir_cache`, `dcache_timeout`, `dcache_max_size`). These are overridden to `false` in config; correct equivalents (`cache`, `cache_timeout`, `cache_max_size`) are set explicitly.
- `Sshfs.build_mount_command` is monkey-patched in `config` too: on macOS 27 + macFUSE 5.4, sshfs 2.10 can't daemonize (`fuse: forking after mount is not supported`, [libfuse/sshfs#388](https://github.com/libfuse/sshfs/issues/388)). It stays in the foreground, and since the plugin waits for sshfs to *exit*, a connect showed only "Connecting to X..." until the mount died, then reported "Connected" for a dead mount (E344 on the auto-`tcd`). The patch wraps the command in `sh -c` that runs `sshfs -f` in the background, polls (up to 15s) until the mount point's device ID differs from its parent's, then exits 0 — or exits 1 with sshfs's stderr if it dies. Remove once sshfs/macFUSE fix daemonizing.
- `MountPoint.unmount` is monkey-patched in the `config` function: tries `umount` first, falls back to `diskutil unmount force`. The plugin's built-in sequence only uses `diskutil unmount` (no force) which reliably fails on macFUSE mounts.

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
| `<leader>D` | fzf-lua | Document diagnostics picker (fuzzy-filter by source, e.g. type `typos`) |
| `<leader>d` / `]d` / `[d` | built-in | Line diagnostic float / next / prev |

"Workspace" diagnostics only cover **open** files: basedpyright uses `diagnosticMode = "openFilesOnly"` and the other servers only analyse buffers they're attached to.

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
| `<leader>rm` | render-markdown | Toggle markdown rendering |
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

## Ruff Configuration

There is deliberately **no `ruff.toml` in this repo**. One used to live here and was broken: it used `[tool.ruff]` / `[tool.ruff.isort]`, which are only valid inside `pyproject.toml`. A standalone `ruff.toml` puts settings at the top level, with `select`/`ignore` under `[lint]` and isort under `[lint.isort]`. Because it failed to *parse*, ruff aborted instead of falling back to defaults, so Python files opened with this directory as cwd got no linting at all and the LSP logged `Error while resolving settings from workspace`.

The corrected config now lives at **`~/.config/ruff/ruff.toml`** (ruff's user-level XDG location), where it applies to any Python file not already covered by a project config. It enables `E`, `F`, `I`, `UP`, `B`, `SIM`, `A`, ignores `E501`, targets py311, and sets `fix = true`.

**Scope caveat:** a project-level `pyproject.toml` or `ruff.toml` *replaces* the user-level file entirely rather than merging with it. Any repo with its own ruff config ignores these settings completely.

---

## Known Issues / TODOs

All three previously-recorded known issues are resolved (see git history):

1. ~~ruff runs twice~~ — fixed; ruff removed from nvim-lint, LSP server is the single source of ruff diagnostics.
2. ~~beautysh and shellcheck unwired~~ — beautysh wired into conform for sh/bash; shellcheck reaches you via bash-language-server.
3. ~~Python path detection is startup-time only~~ — `get_python_path` now runs per project root inside basedpyright's `before_init`.

**luarocks:** `rocks = { enabled = false }` is set in `lazy.lua`. No installed plugin needs a rock — the six shipping a `.rockspec` (gitsigns, nui, nvim-cmp, nvim-lint, nvim-lspconfig, plenary) all have a `/lua` dir, a simple build, and no non-Lua deps. Leaving it enabled only made `:checkhealth lazy` error about an unbuilt hererocks. Re-enable if a future plugin genuinely requires luarocks.

Remaining, non-urgent:

- **`stevearc/dressing.nvim` is archived** upstream (author recommends `snacks.nvim` for `vim.ui.*`). Still functions; no action taken.
- **`szw/vim-maximizer` is ancient** (last upstream commit 2015) but feature-complete.
- **A stale duplicate config exists** at `~/.dotfiles/.config/.config/nvim` (note the doubled `.config`) — an old clone of this same repo at commit `d2410f7`, clean working tree, not on any runtimepath, untouched since Aug 2025. It is 16 commits behind and contains nothing unique. Safe to delete; left in place.
- **`.venv/` (37 MB) sits in this repo** but self-ignores via `.venv/.gitignore` containing `*`, so git never sees it. Note that `get_python_path` will pick its interpreter for any Python file opened with this directory as the project root.

Formatting is consistent repo-wide: `stylua --check lua/ init.lua` passes. There is no `.stylua.toml`, so stylua's defaults (tabs) apply — the same style format-on-save enforces.

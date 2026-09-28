vim.cmd("let g:netrw_liststyle = 3")

vim.api.nvim_create_autocmd("ColorScheme", {
	command = [[highlight CursorLine gui=bold guibg=NONE cterm=underline]],
})

local opt = vim.opt

opt.showtabline = 0

opt.relativenumber = true
opt.number = true

opt.tabstop = 2 -- 2 spaces for tabs (prettier default)
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- expand tab to spaces
opt.autoindent = true -- copy indent from current line when starting new one

opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

-- Preview :substitute results in a split before committing, rather than only
-- highlighting matches inline (the "nosplit" default).
opt.inccommand = "split"

opt.cursorline = true

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

opt.clipboard:append("unnamedplus")

opt.splitright = true
opt.splitbelow = true

opt.swapfile = false

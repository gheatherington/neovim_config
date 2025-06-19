return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPre", "BufNewFile" },
	build = ":TSUpdate",
	dependencies = {
		"windwp/nvim-ts-autotag",
	},
	config = function()
		-- import nvim-treesitter plugin
		local treesitter = require("nvim-treesitter.configs")

		-- configure treesitter
		treesitter.setup({ -- enable syntax highlighting
			highlight = {
				enable = true,
			},
			-- enable indentation
			indent = { enable = true },
			-- enable autotagging (w/ nvim-ts-autotag plugin)
			autotag = {
				enable = true,
			},
			-- ensure these language parsers are installed
			ensure_installed = {
				"json",
				"javascript",
				"typescript",
				"tsx",
				"yaml",
				"html",
				"css",
				"prisma",
				"python",
				"markdown",
				"markdown_inline",
				"svelte",
				"graphql",
				"bash",
				"lua",
				"vim",
				"dockerfile",
				"gitignore",
				"query",
				"vimdoc",
				"c",
			},
			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "<C-space>",
					node_incremental = "<C-space>",
					scope_incremental = false,
					node_decremental = "<bs>",
				},
			},
		})

		-- local opt = vim.opt

		-- Set fold method to 'expr' to allow expression-based folding (e.g., for Tree-sitter)
		-- opt.foldmethod = "expr"
		-- opt.foldexpr = "nvim_treesitter#foldexpr()"
		-- opt.foldlevel = 99 -- Prevent all folds from being closed when you open a file
		-- opt.foldlevelstart = 1
		-- opt.foldenable = true
		-- opt.foldcolumn = "1"

		-- opt.foldtext = ""

		-- local map = vim.keymap
		--
		-- map.set("n", "zR", "zR", { noremap = true }) -- open all folds
		-- map.set("n", "zM", "zM", { noremap = true }) -- close all folds
		-- map.set("n", "za", "za", { noremap = true }) -- toggle fold
		--
		-- opt.foldtext = "v:lua.vim_fold_text()"
		-- function _G.vim_fold_text()
		-- 	local line = vim.fn.getline(vim.v.foldstart)
		-- 	local num_lines = vim.v.foldend - vim.v.foldstart + 1
		-- 	return line .. "  {" .. num_lines .. " lines} "
		-- end
		--
		-- opt.fillchars = {
		-- 	fold = "━",
		-- 	foldopen = "",
		-- 	foldclose = "",
		-- 	foldsep = " ",
		-- }
		--
		-- vim.api.nvim_create_autocmd({ "ColorScheme", "BufWinEnter" }, {
		-- 	pattern = "*",
		-- 	group = vim.api.nvim_create_augroup("UserFoldHighlights", { clear = true }),
		-- 	callback = function()
		-- 		vim.cmd([[
		--     highlight! Folded guibg=NONE guifg=#275378
		--     highlight! FoldColumn guibg=NONE guifg=#7f849c
		--   ]])
		-- 	end,
		-- })

		-- vim.api.nvim_create_autocmd("BufWinEnter", {
		-- 	pattern = "*.*",
		-- 	callback = function()
		-- 		print("loading view")
		-- 		vim.cmd("set foldmethod=expr")
		-- 		vim.cmd("setlocal foldmethod=expr")
		-- 		vim.cmd.loadview()
		-- 		vim.cmd("loadview")
		-- 	end,
		-- })
	end,
}

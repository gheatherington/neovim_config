return {
	"mason-org/mason.nvim",
	dependencies = {
		"neovim/nvim-lspconfig",
		"mason-org/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			-- mason-lspconfig v2 removed setup_handlers/automatic_installation and
			-- added automatic_enable, which defaults to true: every installed
			-- server is vim.lsp.enable()'d automatically. Servers we configure
			-- explicitly in lspconfig.lua are simply enabled twice (idempotent).
			-- Excludes pyright: it was replaced by basedpyright, and if the mason
			-- package lingers on disk automatic_enable would silently run both.
			automatic_enable = {
				exclude = { "pyright" },
			},
			-- list of servers for mason to install
			ensure_installed = {
				"html",
				"cssls",
				"tailwindcss",
				"svelte",
				"lua_ls",
				"graphql",
				"emmet_ls",
				"prismals",
				"basedpyright",
				"bashls",
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"prettier", -- prettier formatter
				"stylua", -- lua formatter
				"ruff", -- python linter (LSP) + formatter
				"eslint_d",
				"beautysh",
				"shellcheck",
			},
		})
	end,
}

return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettier" },
				typescript = { "prettier" },
				javascriptreact = { "prettier" },
				typescriptreact = { "prettier" },
				svelte = { "prettier" },
				css = { "prettier" },
				html = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				markdown = { "prettier" },
				graphql = { "prettier" },
				liquid = { "prettier" },
				lua = { "stylua" },
				sh = { "beautysh" },
				bash = { "beautysh" },
				python = { "ruff_organize_imports", "ruff_format" },
			},
			-- NOTE: timeout_ms is one shared budget for the WHOLE formatter chain
			-- for a filetype, not per-formatter. Python previously chained isort
			-- (~100ms) and black (~150ms) and would intermittently blow a 1000ms
			-- ceiling; ruff does both steps in ~8ms each as a single binary.
			format_on_save = {
				lsp_format = "fallback",
				async = false,
				timeout_ms = 5000,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_format = "fallback",
				async = false,
				timeout_ms = 5000,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}

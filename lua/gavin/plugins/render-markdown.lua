return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
	opts = {},
	config = function()
		local markdown = require("render-markdown")

		local set_hl = vim.api.nvim_set_hl

		set_hl(0, "RenderMarkdownCode", { bg = "#202a38" })
		-- set_hl(0, "RenderMarkdownCodeInfo", { bg = "NONE" })
		-- set_hl(0, "RenderMarkdownCodeBorder", { bg = "NONE" })
		-- set_hl(0, "RenderMarkdownCodeFallback", { bg = "NONE" })
		-- set_hl(0, "RenderMarkdownCodeInline", { bg = "NONE" })

		markdown.setup({
			completions = { lsp = { enabled = true } },
		})

		vim.keymap.set("n", "<leader>rm", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle markdown render" })
	end,
}

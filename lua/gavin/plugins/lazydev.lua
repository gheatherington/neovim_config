return {
	-- Replaces folke/neodev.nvim, which was archived (EOL) on 2024-07-06.
	-- Configures lua_ls for editing Neovim config and plugin code.
	"folke/lazydev.nvim",
	ft = "lua",
	opts = {
		library = {
			-- Load luvit types when the `vim.uv` word is found.
			{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
		},
	},
}

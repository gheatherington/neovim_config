return {
	-- Maintained fork of norcalli/nvim-colorizer.lua (upstream is unmaintained and
	-- still calls the deprecated vim.tbl_flatten).
	"catgoose/nvim-colorizer.lua",
	event = "BufReadPre",
	opts = {
		filetypes = { "*" },
		user_default_options = {
			RGB = true,
			RRGGBB = true,
			names = true,
			RRGGBBAA = true,
			rgb_fn = true,
			hsl_fn = true,
			css = true,
			css_fn = true,
			mode = "background",
		},
	},
}

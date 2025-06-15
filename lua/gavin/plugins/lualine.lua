return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local lualine = require("lualine")
		local lazy_status = require("lazy.status") -- to configure lazy pending updates count

		local colors = {
			blue = "#65D1FF",
			green = "#3EFFDC",
			violet = "#FF61EF",
			yellow = "#FFDA7B",
			red = "#FF4A4A",
			fg = "#c3ccdc",
			color_fg = "#1e1e2e",
			bg = "NONE",
			inactive_bg = "#2c3043",
		}

		local function get_mode_color()
			local mode = vim.fn.mode()
			local mode_colors = {
				n = colors.blue,
				i = colors.green,
				v = colors.violet,
				V = colors.violet,
				[""] = colors.violet,
				c = colors.yellow,
				R = colors.red,
			}

			-- Default to blue if mode isn't recognized
			return mode_colors[mode] or colors.blue
		end

		local my_lualine_theme = {
			normal = {
				a = { bg = colors.blue, fg = colors.color_fg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			insert = {
				a = { bg = colors.green, fg = colors.color_fg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			visual = {
				a = { bg = colors.violet, fg = colors.color_fg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			command = {
				a = { bg = colors.yellow, fg = colors.color_fg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			replace = {
				a = { bg = colors.red, fg = colors.color_fg, gui = "bold" },
				b = { bg = colors.bg, fg = colors.fg },
				c = { bg = colors.bg, fg = colors.fg },
			},
			inactive = {
				a = { bg = colors.inactive_bg, fg = nil, gui = "bold" },
				b = { bg = colors.inactive_bg, fg = nil },
				c = { bg = colors.inactive_bg, fg = nil },
			},
		}

		local opt = vim.opt
		opt.laststatus = 0
		opt.ruler = false
		opt.showmode = false
		opt.cmdheight = 1

		-- configure lualine with modified theme
		lualine.setup({
			options = {
				globalstatus = false,
				theme = my_lualine_theme,
				section_separators = { left = "", right = "" },
				component_separators = { left = "", right = "" },
				always_divide_middle = true,
				disabled_filetypes = {
					statusline = {},
					winbar = { "alpha" },
				},
			},
			sections = {},
			inactive_sections = {},
			winbar = {
				lualine_a = {
					{
						"mode",
						separator = { left = " ", right = "" },
					},
				},
				lualine_b = {
					{
						"filename",
						separator = { left = "", right = "" },
					},
				},
				lualine_c = { "branch", "diff", "diagnostics" },
				lualine_x = {
					{
						lazy_status.updates,
						cond = lazy_status.has_updates,
						color = { fg = "#ff9e64" },
					},
					{ "encoding" },
					{ "fileformat" },
					{ "filetype" },
				},
				lualine_y = { "progress" },
				lualine_z = {
					{
						function()
							return vim.fn.line(".") .. ":" .. vim.fn.col(".")
						end,
						separator = { left = "", right = " " },
					},
				},
			},
			inactive_winbar = {
				lualine_a = {},
				lualine_b = {
					{
						function()
							local name = vim.fn.bufname()
							if name:match("NvimTree_") then
								return "Explorer"
							end
							return vim.fn.expand("%:t") ~= "" and vim.fn.expand("%:t") or "[No Name]"
						end,
						separator = { left = " ", right = " " },
						color = function()
							return {
								fg = get_mode_color(),
								bg = colors.inactive_bg,
								gui = "bold",
							}
						end,
					},
				},
				lualine_c = {},
				lualine_x = {},
				lualine_y = {},
				lualine_z = {},
			},
		})
	end,
}

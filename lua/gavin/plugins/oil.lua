return {
	"stevearc/oil.nvim",
	lazy = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("oil").setup({
			default_file_explorer = false,
			keymaps = {
				["<C-h>"] = false, -- conflicts with vim-tmux-navigator
				["<C-l>"] = false, -- conflicts with vim-tmux-navigator
			},
		})

		local keymap = vim.keymap.set

		keymap("n", "-", "<cmd>Oil<CR>", { desc = "Open file explorer (oil)" })

		keymap("n", "<leader>Ro", function()
			vim.ui.input({ prompt = "SSH (user@host:/path): " }, function(input)
				if input and input ~= "" then
					-- "user@host" → home, "user@host:rel" → ~/rel, "user@host:/abs" → /abs.
					-- oil-ssh paths are home-relative after one slash; an absolute
					-- path needs a second one (oil-ssh://host//abs).
					local host, path = input:match("^([^:]+):?(.*)$")
					if path ~= "" and path:sub(-1) ~= "/" then
						path = path .. "/"
					end
					vim.cmd("Oil oil-ssh://" .. host .. "/" .. path)
				end
			end)
		end, { desc = "Remote: open SSH directory" })
	end,
}

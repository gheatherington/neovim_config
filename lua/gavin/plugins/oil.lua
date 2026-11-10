return {
	"stevearc/oil.nvim",
	lazy = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		-- oil-ssh lists directories over an interactive ssh session, but reads and
		-- writes files with a separate scp that has no terminal, so scp can't ask
		-- for a password. Sharing one multiplexed connection lets scp reuse the
		-- session you already authenticated. Same socket path as sshfs.nvim.
		local socket_dir = vim.fn.expand("~/.ssh/sockets")
		local control_path = socket_dir .. "/%C"
		vim.fn.mkdir(socket_dir, "p", tonumber("700", 8))

		local connection = require("oil.adapters.ssh.connection")
		local create_ssh_command = connection.create_ssh_command
		connection.create_ssh_command = function(url)
			local command = create_ssh_command(url)
			local options = {
				"-o",
				"ControlMaster=auto",
				"-o",
				"ControlPath=" .. control_path,
				"-o",
				"ControlPersist=10m",
			}
			for i, option in ipairs(options) do
				table.insert(command, 1 + i, option)
			end
			return command
		end

		require("oil").setup({
			default_file_explorer = false,
			extra_scp_args = { "-o", "ControlPath=" .. control_path },
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

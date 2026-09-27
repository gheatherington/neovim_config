return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"mason-org/mason.nvim",
		"mason-org/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
	},
	config = function()
		-- import cmp-nvim-lsp plugin
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		local keymap = vim.keymap -- for conciseness

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings.
				-- See `:help vim.lsp.*` for documentation on any of the below functions
				local opts = { buffer = ev.buf, silent = true }

				-- set keybinds
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", "<cmd>FzfLua lsp_references<CR>", opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<CR>", opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<CR>", opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", "<cmd>FzfLua lsp_typedefs<CR>", opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", "<cmd>FzfLua diagnostics_document<CR>", opts)

				opts.desc = "LSP finder (refs + defs + impls)"
				keymap.set("n", "gF", "<cmd>FzfLua lsp_finder<CR>", opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

				-- vim.diagnostic.goto_prev/goto_next were deprecated in 0.11 in favour
				-- of vim.diagnostic.jump(); the JumpOpts `float` key was in turn
				-- deprecated in 0.12, so use on_jump/defaults instead.
				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", function()
					vim.diagnostic.jump({ count = -1 })
				end, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", function()
					vim.diagnostic.jump({ count = 1 })
				end, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
			end,
		})

		-- Advertise nvim-cmp's completion capabilities to every server.
		vim.lsp.config("*", {
			capabilities = cmp_nvim_lsp.default_capabilities(),
		})

		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = "",
					[vim.diagnostic.severity.WARN] = "",
					[vim.diagnostic.severity.HINT] = "󰠠",
					[vim.diagnostic.severity.INFO] = "",
				},
				numhl = {
					[vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
					[vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
					[vim.diagnostic.severity.HINT] = "DiagnosticSignHint",
					[vim.diagnostic.severity.INFO] = "DiagnosticSignInfo",
				},
				linehl = {
					[vim.diagnostic.severity.ERROR] = "ErrorMsg",
				},
			},
		})

		vim.lsp.config("bashls", {
			cmd = { "bash-language-server", "start" },
			filetypes = { "bash", "sh" },
		})
		vim.lsp.enable("bashls")

		-- Resolve the interpreter for a given project root: prefer an in-project
		-- venv, then an activated $VIRTUAL_ENV, then whatever is on $PATH.
		local function get_python_path(workspace)
			if workspace then
				for _, dir in ipairs({ ".venv", "venv", ".env" }) do
					local candidate = vim.fs.joinpath(workspace, dir, "bin", "python")
					if vim.fn.executable(candidate) == 1 then
						return candidate
					end
				end
			end

			local venv = vim.env.VIRTUAL_ENV
			if venv then
				local candidate = vim.fs.joinpath(venv, "bin", "python")
				if vim.fn.executable(candidate) == 1 then
					return candidate
				end
			end

			local exe = vim.fn.exepath("python3")
			if exe == "" then
				exe = vim.fn.exepath("python")
			end
			return exe ~= "" and exe or nil
		end

		vim.lsp.enable("ruff")

		vim.lsp.config("pyright", {
			settings = {
				python = {
					analysis = {
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						diagnosticMode = "workspace", -- full project scan
					},
				},
			},
			-- Resolved per project root rather than once at startup, so opening a
			-- file in another project picks up that project's venv.
			before_init = function(_, config)
				local python_path = get_python_path(config.root_dir)
				if python_path then
					config.settings.python.pythonPath = python_path
				end
			end,
		})

		vim.lsp.enable("pyright")

		vim.lsp.config("lua_ls", {
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					completion = {
						callSnippet = "Replace",
					},
				},
			},
		})
		vim.lsp.enable("lua_ls")
	end,
}

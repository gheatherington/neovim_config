return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			svelte = { "eslint_d" },
			-- `zsh --no-exec` catches syntax errors; shellcheck_zsh the rest
			zsh = { "zsh", "shellcheck_zsh" },
			-- NOTE: python/sh/bash are deliberately absent here. ruff already runs
			-- as an LSP server (vim.lsp.enable("ruff")) and bash-language-server
			-- runs shellcheck internally; listing either as a nvim-lint linter
			-- too produced every diagnostic twice.
		}

		-- ShellCheck refuses zsh (and bashls skips it), so lint zsh as bash and
		-- drop the checks where zsh behaves differently. Without this, mistakes
		-- like an unset variable (SC2154) go unreported in zsh files.
		--   SC1xxx: parse errors. The bash parser gives up on zsh-only syntax
		--           (glob qualifiers, `if [[ ]] { }`); the zsh linter reports
		--           real syntax errors instead.
		--   SC2086/SC2068: zsh doesn't word-split unquoted expansions
		--   SC2128/SC2178: zsh expands $array to every element
		--   SC2051: zsh allows variables in {1..$n}
		--   SC2296: zsh parameter flags like ${(k)assoc}
		--   SC2154 on zsh's lowercase special parameters ($path, $reply, ...),
		--           which bash doesn't have (uppercase ones are never flagged)
		local zsh_specials = {}
		for _, name in ipairs({
			"path",
			"fpath",
			"cdpath",
			"manpath",
			"mailpath",
			"module_path",
			"fignore",
			"argv",
			"pipestatus",
			"status",
			"psvar",
			"reply",
			"match",
			"mbegin",
			"mend",
			"commands",
			"options",
			"parameters",
			"functions",
			"aliases",
			"builtins",
			"history",
			"historywords",
			"dirstack",
			"jobstates",
			"jobtexts",
			"modules",
			"widgets",
			"keymaps",
			"signals",
			"userdirs",
			"nameddirs",
			"termcap",
			"terminfo",
			"funcstack",
			"funcfiletrace",
			"funcsourcetrace",
			"functrace",
			"zsh_eval_context",
			"precmd_functions",
			"preexec_functions",
			"chpwd_functions",
			"periodic_functions",
			"zshaddhistory_functions",
			"zshexit_functions",
			"watch",
			"region_highlight",
			"killring",
		}) do
			zsh_specials[name] = true
		end
		local shellcheck = lint.linters.shellcheck
		lint.linters.shellcheck_zsh = vim.tbl_extend("force", shellcheck, {
			-- stdin rather than the file on disk, so unsaved edits are linted
			args = {
				"--format",
				"json1",
				"--shell=bash",
				"--exclude=SC2086,SC2068,SC2128,SC2178,SC2051,SC2296",
				"-",
			},
			parser = function(output, bufnr, cwd)
				return vim.tbl_filter(function(d)
					if d.code < 2000 then
						return false
					end
					local var = d.code == 2154 and d.message:match("^(%S+) is referenced")
					return not (var and zsh_specials[var])
				end, shellcheck.parser(output, bufnr, cwd))
			end,
		})

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>l", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}

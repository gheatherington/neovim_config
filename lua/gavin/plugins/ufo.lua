return {
	"kevinhwang91/nvim-ufo",
	dependencies = {
		"kevinhwang91/promise-async",
	},
	config = function()
		local ufo = require("ufo")
		local opt = vim.opt

		opt.foldlevel = 99
		opt.foldlevelstart = 99
		opt.foldenable = true
		opt.foldcolumn = "1"
		-- vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep:┃,foldclose:]]
		opt.statuscolumn =
			'%=%s%l %@v:lua.GavinFoldClick@%{foldlevel(v:lnum) > 0 ? (foldlevel(v:lnum) > foldlevel(v:lnum - 1) ? (foldclosed(v:lnum) == -1 ? "" : "") : " ") : " " }%T'

		-- Left-click on a fold arrow toggles that fold (the arrow is wrapped in
		-- %@...%T above). Only acts on lines that show an arrow.
		function _G.GavinFoldClick(_, _, button, _)
			if button ~= "l" then
				return
			end
			local pos = vim.fn.getmousepos()
			if pos.winid == 0 or pos.line == 0 then
				return
			end
			vim.api.nvim_win_call(pos.winid, function()
				local lnum = pos.line
				if vim.fn.foldclosed(lnum) ~= -1 then
					vim.cmd(lnum .. "foldopen")
				elseif vim.fn.foldlevel(lnum) > vim.fn.foldlevel(lnum - 1) then
					vim.cmd(lnum .. "foldclose")
				end
			end)
		end

		local map = vim.keymap

		map.set("n", "zR", ufo.openAllFolds, { desc = "Open all folds" })
		map.set("n", "zM", ufo.closeAllFolds, { desc = "Close all folds" })
		map.set("n", "za", "za", { noremap = true }) -- toggle fold
		map.set("n", "zK", function()
			local winid = ufo.peekFoldedLinesUnderCursor()
			if not winid then
				vim.lsp.buf.hover()
			end
		end, { desc = "Peek Fold" })

		local handler = function(virtText, lnum, endLnum, width, truncate)
			local newVirtText = {}
			local suffix = (" 󰁂 [%d lines] "):format(endLnum - lnum)
			local sufWidth = vim.fn.strdisplaywidth(suffix)
			local targetWidth = width - sufWidth
			local curWidth = 0
			for _, chunk in ipairs(virtText) do
				local chunkText = chunk[1]
				local chunkWidth = vim.fn.strdisplaywidth(chunkText)
				if targetWidth > curWidth + chunkWidth then
					table.insert(newVirtText, chunk)
				else
					chunkText = truncate(chunkText, targetWidth - curWidth)
					local hlGroup = chunk[2]
					table.insert(newVirtText, { chunkText, hlGroup })
					chunkWidth = vim.fn.strdisplaywidth(chunkText)
					-- str width returned from truncate() may less than 2nd argument, need padding
					if curWidth + chunkWidth < targetWidth then
						suffix = suffix .. (" "):rep(targetWidth - curWidth - chunkWidth)
					end
					break
				end
				curWidth = curWidth + chunkWidth
			end
			table.insert(newVirtText, { suffix, "MoreMsg" })
			return newVirtText
		end

		vim.cmd("hi Folded guibg=NONE")

		-- Python: neither basedpyright nor indent folding gives a docstring its own
		-- fold (its lines share the body's indent), so add one per multi-line
		-- string statement, found with treesitter, on top of the lsp/indent folds.
		local docstring_query = vim.treesitter.query.parse("python", "(expression_statement (string) @doc)")

		local function add_docstring_folds(bufnr, ranges)
			if not ranges then
				return ranges
			end
			local parser = vim.treesitter.get_parser(bufnr, "python", { error = false })
			if not parser then
				return ranges
			end
			local root = parser:parse()[1]:root()
			local starts = {}
			for _, r in ipairs(ranges) do
				starts[r.startLine] = true
			end
			for _, node in docstring_query:iter_captures(root, bufnr) do
				local srow, _, erow = node:range()
				if erow > srow and not starts[srow] then
					table.insert(ranges, { startLine = srow, endLine = erow })
					starts[srow] = true
				end
			end
			return ranges
		end

		local function python_folds(bufnr)
			return ufo.getFolds(bufnr, "lsp")
				:catch(function(err)
					if type(err) == "string" and err:match("UfoFallbackException") then
						return ufo.getFolds(bufnr, "indent")
					end
					return require("promise").reject(err)
				end)
				:thenCall(function(ranges)
					return add_docstring_folds(bufnr, ranges)
				end)
		end

		ufo.setup({
			open_fold_hl_timeout = 150,
			close_fold_kinds_for_ft = {
				default = { "imports", "comment" },
				json = { "array" },
				c = { "comment", "region" },
			},
			close_fold_current_line_for_ft = {
				default = true,
				c = false,
			},
			preview = {
				win_config = {
					border = { "", "─", "", "", "", "─", "", "" },
					winhighlight = "Normal:Folded",
					winblend = 0,
				},
				mappings = {
					scrollU = "<C-u>",
					scrollD = "<C-d>",
					jumpTop = "[",
					jumpBot = "]",
				},
			},
			fold_virt_text_handler = handler,
			provider_selector = function(_, filetype)
				if filetype == "python" then
					return python_folds
				end
				return { "lsp", "indent" }
			end,
		})
	end,
}

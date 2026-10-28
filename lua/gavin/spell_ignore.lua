-- Per-file ignore list for the spell-checking servers (harper, codebook, typos).
--
-- Only harper has a native per-file dictionary; codebook and typos can only
-- accept a word globally or skip a whole file. So instead, keep our own list of
-- ignored words per file and drop matching diagnostics from those servers
-- before Neovim displays them. Matching is on the flagged text, ignoring case.
-- The list persists across sessions in stdpath("data")/spell-ignore.json.

local M = {}

local SERVERS = { harper_ls = true, codebook = true, typos_lsp = true }

local store_path = vim.fs.joinpath(vim.fn.stdpath("data"), "spell-ignore.json")

---@type table<string, string[]>? file path -> ignored words (lowercase)
local store

local function load()
	if store then
		return store
	end
	store = {}
	local f = io.open(store_path, "r")
	if f then
		local ok, data = pcall(vim.json.decode, f:read("*a"))
		f:close()
		if ok and type(data) == "table" then
			store = data
		end
	end
	return store
end

local function save()
	local f = assert(io.open(store_path, "w"))
	f:write(vim.json.encode(store))
	f:close()
end

--- Ignored words for a buffer as a set, or nil if there are none.
local function ignored(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	local words = name ~= "" and load()[vim.fs.normalize(name)]
	if not words or #words == 0 then
		return nil
	end
	local set = {}
	for _, w in ipairs(words) do
		set[w] = true
	end
	return set
end

--- Text of a single-line range in a buffer; nil for multi-line ranges.
local function text(bufnr, lnum, col, end_lnum, end_col)
	if lnum ~= end_lnum then
		return nil
	end
	local ok, lines = pcall(vim.api.nvim_buf_get_text, bufnr, lnum, col, end_lnum, end_col, {})
	return ok and lines[1] or nil
end

--- Text of an LSP diagnostic's range, converting its column offsets to bytes.
local function lsp_text(bufnr, range, encoding)
	local s, e = range.start, range["end"]
	if s.line ~= e.line then
		return nil
	end
	local line = vim.api.nvim_buf_get_lines(bufnr, s.line, s.line + 1, false)[1]
	if not line then
		return nil
	end
	local ok1, scol = pcall(vim.str_byteindex, line, encoding, s.character, false)
	local ok2, ecol = pcall(vim.str_byteindex, line, encoding, e.character, false)
	return ok1 and ok2 and line:sub(scol + 1, ecol) or nil
end

--- Drop LSP diagnostics whose text is ignored for the buffer at `uri`.
local function filter_lsp(client_id, uri, diagnostics)
	local client = vim.lsp.get_client_by_id(client_id)
	if not client or not SERVERS[client.name] or not diagnostics then
		return diagnostics
	end
	local bufnr = vim.fn.bufnr(vim.uri_to_fname(uri))
	local words = bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) and ignored(bufnr)
	if not words then
		return diagnostics
	end
	return vim.tbl_filter(function(d)
		local t = lsp_text(bufnr, d.range, client.offset_encoding)
		return not (t and words[t:lower()])
	end, diagnostics)
end

--- Spell-server name a diagnostic namespace belongs to, or nil.
local function server_for(ns)
	local name = vim.diagnostic.get_namespace(ns).name or ""
	local server = name:match("^nvim%.lsp%.([%w_]+)%.")
	return SERVERS[server] and server or nil
end

--- Ignore the flagged word under the cursor in the current file.
function M.ignore_word()
	local bufnr = vim.api.nvim_get_current_buf()
	local name = vim.api.nvim_buf_get_name(bufnr)
	if name == "" then
		vim.notify("Buffer has no file name", vim.log.levels.WARN)
		return
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local word
	for _, d in ipairs(vim.diagnostic.get(bufnr, { lnum = row - 1 })) do
		local end_col = d.end_col or d.col
		if server_for(d.namespace) and d.col <= col and (col < end_col or col == d.col) then
			local t = text(bufnr, d.lnum, d.col, d.end_lnum or d.lnum, end_col)
			-- Prefer the narrowest match, e.g. a spelling lint over a grammar one
			if t and t ~= "" and (not word or #t < #word) then
				word = t
			end
		end
	end
	if not word then
		vim.notify("No spelling diagnostic under cursor", vim.log.levels.WARN)
		return
	end

	local path = vim.fs.normalize(name)
	local words = load()[path] or {}
	if not vim.tbl_contains(words, word:lower()) then
		table.insert(words, word:lower())
	end
	store[path] = words
	save()

	-- Clear the existing diagnostics now rather than waiting for the next publish
	local set = ignored(bufnr)
	for ns in pairs(vim.diagnostic.get_namespaces()) do
		if server_for(ns) then
			local kept = vim.tbl_filter(function(d)
				local t = text(bufnr, d.lnum, d.col, d.end_lnum or d.lnum, d.end_col or d.col)
				return not (t and set[t:lower()])
			end, vim.diagnostic.get(bufnr, { namespace = ns }))
			vim.diagnostic.set(ns, bufnr, kept)
		end
	end
	vim.notify(('Ignoring "%s" in %s'):format(word, vim.fn.fnamemodify(name, ":t")))
end

function M.setup()
	local push = "textDocument/publishDiagnostics"
	local orig_push = vim.lsp.handlers[push]
	vim.lsp.handlers[push] = function(err, result, ctx, ...)
		if result then
			result.diagnostics = filter_lsp(ctx.client_id, result.uri, result.diagnostics)
		end
		return orig_push(err, result, ctx, ...)
	end

	local pull = "textDocument/diagnostic"
	local orig_pull = vim.lsp.handlers[pull]
	vim.lsp.handlers[pull] = function(err, result, ctx, ...)
		if result and result.kind == "full" then
			result.items = filter_lsp(ctx.client_id, ctx.params.textDocument.uri, result.items)
		end
		return orig_pull(err, result, ctx, ...)
	end
end

return M

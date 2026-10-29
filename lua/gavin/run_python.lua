-- Run the current Python file in a centred floating terminal (<leader>rp).
-- The interpreter is resolved the same way basedpyright resolves it, so a
-- project's venv is used without activating it first.

local M = {}

local root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".venv", "venv", ".git" }

-- Resolve the interpreter for a given project root: prefer an in-project
-- venv, then an activated $VIRTUAL_ENV, then whatever is on $PATH.
function M.python_path(workspace)
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

function M.run()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		vim.notify("Save the buffer to a file first", vim.log.levels.WARN)
		return
	end
	if vim.bo.modified then
		vim.cmd.write()
	end

	local dir = vim.fs.dirname(file)
	local python = M.python_path(vim.fs.root(file, root_markers) or dir)
	if not python then
		vim.notify("No Python interpreter found", vim.log.levels.ERROR)
		return
	end

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " " .. vim.fs.basename(file) .. " ",
		title_pos = "center",
	})
	vim.bo[buf].bufhidden = "wipe"

	-- -i keeps the interpreter open afterwards, with the script's globals loaded
	vim.fn.jobstart({ python, "-i", file }, { term = true, cwd = dir })
	vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, desc = "Close output" })
	vim.cmd.startinsert()
end

function M.setup()
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "python",
		callback = function(ev)
			vim.keymap.set("n", "<leader>rp", M.run, { buffer = ev.buf, desc = "Run Python file in popup" })
		end,
	})
end

return M

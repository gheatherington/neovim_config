-- Insert a "TODO: " comment above the cursor line, using the buffer's commentstring,
-- and start insert mode right after the keyword.
local function add_todo()
	local cs = vim.bo.commentstring
	if not cs:find("%%s") then
		cs = "# %s"
	end
	local left, right = cs:match("^(.-)%%s(.-)$")
	if left ~= "" and not left:match("%s$") then
		left = left .. " "
	end
	if right ~= "" and not right:match("^%s") then
		right = " " .. right
	end

	local row = vim.api.nvim_win_get_cursor(0)[1]
	local indent = vim.api.nvim_get_current_line():match("^%s*")
	local prefix = indent .. left .. "TODO: "
	vim.api.nvim_buf_set_lines(0, row - 1, row - 1, false, { prefix .. right })

	vim.api.nvim_win_set_cursor(0, { row, #prefix })
	-- With no closing delimiter the cursor sits past the end of the line, so append instead
	vim.cmd(right == "" and "startinsert!" or "startinsert")
end

return {
	"folke/todo-comments.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = { "nvim-lua/plenary.nvim" },
	opts = {},
	keys = {
		{
			"]t",
			function()
				require("todo-comments").jump_next()
			end,
			desc = "Next todo comment",
		},
		{
			"[t",
			function()
				require("todo-comments").jump_prev()
			end,
			desc = "Previous todo comment",
		},
		{ "<leader>ta", add_todo, desc = "Add todo comment above line" },
		{ "<leader>xt", "<cmd>Trouble todo toggle<CR>", desc = "Open todos in trouble" },
		{ "<leader>ft", "<cmd>TodoFzfLua<CR>", desc = "Find todos" },
	},
}

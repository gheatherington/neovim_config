return {
  "alexpasmantier/tv.nvim",
  config = function()
    local h = require("tv").handlers

    require("tv").setup({
      window = {
        width = 0.8,
        height = 0.8,
        border = "rounded",
      },
      channels = {
        files = {
          keybinding = "<leader>ff",
          handlers = {
            ["<CR>"] = h.open_as_files,
            ["<C-q>"] = h.send_to_quickfix,
            ["<C-s>"] = h.open_in_split,
            ["<C-v>"] = h.open_in_vsplit,
            ["<C-y>"] = h.copy_to_clipboard,
          },
        },
        text = {
          keybinding = "<leader>fs",
          handlers = {
            ["<CR>"] = h.open_at_line,
            ["<C-q>"] = h.send_to_quickfix,
            ["<C-s>"] = h.open_in_split,
            ["<C-v>"] = h.open_in_vsplit,
            ["<C-y>"] = h.copy_to_clipboard,
          },
        },
      },
      tv_binary = "tv",
      global_keybindings = {
        channels = "<leader>tv",
      },
      quickfix = {
        auto_open = true,
      },
    })

    -- Find string under cursor (pre-populate query with word under cursor)
    vim.keymap.set("n", "<leader>fc", function()
      vim.cmd("Tv text @" .. vim.fn.expand("<cword>"))
    end, { desc = "Find string under cursor in cwd" })

    -- Recent files
    vim.keymap.set("n", "<leader>fr", "<cmd>Tv recent-files<cr>", { desc = "Fuzzy find recent files" })

    -- Fix vim-tmux-navigator hijacking <C-j>/<C-k> inside tv terminal buffers.
    -- Send the raw byte sequences directly to the terminal channel instead.
    vim.api.nvim_create_autocmd("TermOpen", {
      callback = function(ev)
        local buf_name = vim.api.nvim_buf_get_name(ev.buf)
        if buf_name:find("/tv[%s/:]") or buf_name:find("/tv$") then
          vim.keymap.set("t", "<C-j>", function()
            vim.api.nvim_chan_send(vim.b.terminal_job_id, "\x0a")
          end, { buffer = ev.buf })
          vim.keymap.set("t", "<C-k>", function()
            vim.api.nvim_chan_send(vim.b.terminal_job_id, "\x0b")
          end, { buffer = ev.buf })
        end
      end,
    })
  end,
}

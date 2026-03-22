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
          -- support both "user@host" and "user@host:/path" formats
          local host, path = input:match("^([^:]+):?(.*)")
          path = (path and path ~= "") and path or "/"
          vim.cmd("Oil oil-ssh://" .. host .. path)
        end
      end)
    end, { desc = "Remote: open SSH directory" })
  end,
}

return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("fzf-lua").setup({
      winopts = {
        height = 0.8,
        width = 0.8,
        border = "rounded",
      },
    })
  end,
}

return {
  {
    "vim-ruby/vim-ruby",
    ft = "ruby",
  },
  {
    dir = "~/.vim/bundle/vim-ruby-xmpfilter", -- adjust if needed
    ft = "ruby",
    config = function()
      vim.g.xmpfilter_cmd = "seeing_is_believing"

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "ruby",
        callback = function()
          local opts = { buffer = true }

          vim.keymap.set("n", "<leader>e", "<Plug>(seeing_is_believing-mark)", opts)
          vim.keymap.set("x", "<leader>e", "<Plug>(seeing_is_believing-mark)", opts)
          vim.keymap.set("i", "<leader>e", "<Plug>(seeing_is_believing-mark)", opts)

          vim.keymap.set("n", "<leader>u", "<Plug>(seeing_is_believing-clean)", opts)
          vim.keymap.set("x", "<leader>u", "<Plug>(seeing_is_believing-clean)", opts)
          vim.keymap.set("i", "<leader>u", "<Plug>(seeing_is_believing-clean)", opts)

          vim.keymap.set("n", "<leader>r", "<Plug>(seeing_is_believing-run_-x)", opts)
          vim.keymap.set("x", "<leader>r", "<Plug>(seeing_is_believing-run_-x)", opts)
          vim.keymap.set("i", "<leader>r", "<Plug>(seeing_is_believing-run_-x)", opts)

          vim.keymap.set("n", "<F5>", "<Plug>(seeing_is_believing-run)", opts)
          vim.keymap.set("x", "<F5>", "<Plug>(seeing_is_believing-run)", opts)
          vim.keymap.set("i", "<F5>", "<Plug>(seeing_is_believing-run)", opts)
        end,
      })
    end,
  },
}


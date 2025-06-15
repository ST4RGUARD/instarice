return {
  -- Other plugins you might have
  "nvim-lua/plenary.nvim",
  "christoomey/vim-tmux-navigator",

  {
    'rust-lang/rust.vim',
    ft = "rust",
    init = function()
      vim.g.rustfmt_autosave = 1
    end
  },

}

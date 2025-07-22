return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    require("toggleterm").setup({
      size = 10,           -- for horizontal or vertical
      open_mapping = [[<C-\>]],
      direction = "float", -- can be "horizontal", "vertical", "float", or "tab"
      float_opts = {
        width = 100,
        height = 20,
        border = "curved",
        winblend = 0,
      },
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
    })

    vim.keymap.set('n', '<leader>ts', '<cmd>ToggleTerm<cr>', { desc = 'Toggle floating terminal' })
  end,
}

return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    require('oil').setup {
      default_file_explorer = true,
      columns = {},
      keymaps = {
        ['<C-h>'] = false,
        ['<C-c>'] = false,
        ['<M-h>'] = 'actions.select_split',
        ['q'] = 'actions.close',
      },
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
      },
      skip_confirm_for_simple_edits = true,
    }

    vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent dir' })
    vim.keymap.set('n', '<leader>-', require('oil').toggle_float, { desc = 'toggle float oil' })
  end,
}

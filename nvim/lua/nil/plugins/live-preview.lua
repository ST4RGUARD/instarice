return {
  'brianhuster/live-preview.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    require('live-preview').setup({
      telescope = { autoload = true },
    })

    -- Keymaps
    local map = vim.keymap.set
    local opts = { noremap = true, silent = true, desc = "" }

    map("n", "<leader>lp", ":LivePreview start<CR>", { desc = "Start Live Preview (current file)" })
    map("n", "<leader>ls", ":LivePreview close<CR>", { desc = "Stop Live Preview" })

    -- leader lk also will send a .ipynb notebook that was converted to markdown upon opening to render in browser
    vim.keymap.set("n", "<leader>lk", ":LivePreview pick<CR>", { desc = "LivePreview Picker" })
  end,
}

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

    map("n", "<leader>lj", function()
      require("telescope.builtin").find_files({
        prompt_title = "LivePreview Pick",
        attach_mappings = function(_, map)
          map("i", "<CR>", function(bufnr)
            local entry = require("telescope.actions.state").get_selected_entry()
            require("telescope.actions").close(bufnr)
            vim.cmd("LivePreview " .. entry.value)
          end)
          return true
        end,
      })
    end, { desc = "Custom LivePreview Picker" })
  end,
}

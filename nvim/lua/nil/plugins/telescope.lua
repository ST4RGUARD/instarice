return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")

    telescope.load_extension("fzf")

    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
          },
        },
        extensions = {
        }
      }
    })

    -- oil buffer grep
    local path = require("nil.core.utils.buffer_dir")

    vim.keymap.set("n", "<leader>/", function()
      local word = vim.fn.expand("<cWORD>")
      builtin.live_grep({
        search = word,
        cwd = path.get_buffer_dir(),
      })
    end, { desc = "Oil Grep" })
  end
}

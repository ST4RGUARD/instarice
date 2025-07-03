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
    local function get_current_buffer_dir()
      local bufname = vim.api.nvim_buf_get_name(0)
      local ft = vim.bo.filetype

      if ft == "oil" then
        local dir = bufname:gsub("^oil://", "")
        return dir
      elseif bufname ~= "" then
        return vim.fn.expand("%:p:h")
      else
        return vim.loop.cwd()
      end
    end

    vim.keymap.set("n", "<leader>/", function()
      local word = vim.fn.expand("<cWORD>")
      builtin.live_grep({
        cwd = get_current_buffer_dir(),
      })
    end, { desc = "Oil Grep" })
  end
}

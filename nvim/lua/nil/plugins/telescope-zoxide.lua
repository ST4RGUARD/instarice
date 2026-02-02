return {
  "jvgrootveld/telescope-zoxide",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    telescope.load_extension("zoxide")

    local function open_zoxide()
      telescope.extensions.zoxide.list({
        attach_mappings = function(_, map)
          local function jump(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
          end

          map("i", "<CR>", jump)
          map("n", "<CR>", jump)
          return true
        end,

        -- This hook runs after the picker opens
        on_open = function(prompt_bufnr)
          local picker = action_state.get_current_picker(prompt_bufnr)
          local preview_win = picker and picker.preview_win
          local preview_buf = picker and picker.preview_bufnr

          if preview_buf and vim.api.nvim_buf_is_valid(preview_buf) then
            vim.api.nvim_buf_set_option(preview_buf, "wrap", true)
            vim.api.nvim_buf_set_option(preview_buf, "linebreak", true)
            vim.api.nvim_buf_set_option(preview_buf, "breakindent", true)
          end

          -- Optional: make sure the preview window scrolls with cursor
          if preview_win and vim.api.nvim_win_is_valid(preview_win) then
            vim.api.nvim_win_set_option(preview_win, "scrollbind", false)
          end
        end,
      })
    end

    vim.keymap.set("n", "<leader>z", open_zoxide, {
      desc = "Zoxide Directory Jump (Oil-safe)",
    })

    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        if vim.fn.argc() == 0 then
          open_zoxide()
        end
      end,
    })
  end,
}

return {
  "jvgrootveld/telescope-zoxide",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    local telescope = require("telescope")
    telescope.load_extension("zoxide")

    vim.keymap.set("n", "<leader>z", function()
      -- Call the picker with a direct callback
      telescope.extensions.zoxide.list({
        callback = function(selection)
          require("oil").open({
            force = true,
            directory = selection.path,
          })
        end,
      })
    end, { desc = "Zoxide Directory Jump" })

    -- The autocmd for starting with no arguments also uses a direct callback
    vim.api.nvim_create_autocmd("VimEnter", {
      callback = function()
        -- Check if no files/arguments were passed
        if vim.fn.argc() == 0 then
          -- Load telescope and call the zoxide extension picker
          local ok, telescope = pcall(require, "telescope")
          if ok and telescope.extensions and telescope.extensions.zoxide then
            telescope.extensions.zoxide.list()
          end
        end
      end,
    })
  end,
}

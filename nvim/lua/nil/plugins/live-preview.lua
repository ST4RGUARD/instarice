return {
  'brianhuster/live-preview.nvim',
  dependencies = {
    'nvim-telescope/telescope.nvim',
  },
  config = function()
    local live_preview = require("live-preview")
    live_preview.setup({
      telescope = { autoload = true },
    })

    -- Monkey-patch live-preview start to trigger event
    local original_start = live_preview.start
    live_preview.start = function(...)
      original_start(...)
      vim.schedule(function()
        vim.cmd("doautocmd User LivePreviewStarted")
      end)
    end

    -- Auto-open browser when event is triggered
    vim.api.nvim_create_autocmd("User", {
      pattern = "LivePreviewStarted",
      callback = function()
        -- Use the correct path from live-preview (e.g. ibm/ds/text.md)
        local path = vim.fn.expand("%:p")
        local relative = path:gsub(vim.fn.getcwd() .. "/", "")
        local url = "http://localhost:5500/" .. relative
        vim.fn.jobstart({ "open", url }, { detach = true })
      end,
    })

    -- Keymaps
    local map = vim.keymap.set
    map("n", "<leader>lp", ":LivePreview start<CR>", { desc = "Start Live Preview (current file)" })
    map("n", "<leader>ls", ":LivePreview close<CR>", { desc = "Stop Live Preview" })
    map("n", "<leader>lk", ":LivePreview pick<CR>", { desc = "LivePreview Picker" })
  end
}

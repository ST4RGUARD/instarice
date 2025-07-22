return {
  "rcarriga/nvim-dap-ui",
  dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
  config = function()
    local dapui = require("dapui")
    dapui.setup()

    vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
    vim.keymap.set("n", "<leader>dU", dapui.close, { desc = "Close DAP UI" })
  end,
}

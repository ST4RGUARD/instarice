return {
  "mfussenegger/nvim-dap-python",
  dependencies = { "mfussenegger/nvim-dap" },
  config = function()
    -- Replace this path if needed
    local mason_debugpy_python = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
    require("dap-python").setup(mason_debugpy_python)
  end,
}

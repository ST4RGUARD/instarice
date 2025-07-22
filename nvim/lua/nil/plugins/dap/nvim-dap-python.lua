return {
  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local dap_python = require("dap-python")

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end

      local python_path = vim.fn.exepath("python")
      if python_path == "" then
        vim.notify("[dap-python] Couldn't determine active Python executable", vim.log.levels.ERROR)
        return
      end

      dap_python.setup(python_path)

      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Debug current Python file",
          program = "${file}",
          console = "integratedTerminal",
          cwd = function()
            return vim.fn.expand("%:p:h")
          end,
          env = {
            PYTHONPATH = vim.fn.expand("%:p:h"),
          },
        },
      }
    end,
  },
}

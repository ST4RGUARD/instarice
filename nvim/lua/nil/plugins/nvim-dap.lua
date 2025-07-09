return {
  "mfussenegger/nvim-dap",
  config = function()
    vim.keymap.set("n", "<leader>dl", "<cmd>lua require'dap'.step_into()<CR>", { desc = "Debugger step into" })
    vim.keymap.set("n", "<leader>dj", "<cmd>lua require'dap'.step_over()<CR>", { desc = "Debugger step over" })
    vim.keymap.set("n", "<leader>dk", "<cmd>lua require'dap'.step_out()<CR>", { desc = "Debugger step out" })
    vim.keymap.set("n", "<leader>dc", "<cmd>lua require'dap'.continue()<CR>", { desc = "Debugger continue" })
    vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle Breakpoint" })
    vim.keymap.set("n", "<leader>dd",
      "<cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
      { desc = "Conditional Breakpoint" })
    vim.keymap.set("n", "<leader>de", "<cmd>lua require'dap'.terminate()<CR>", { desc = "Reset" })
    vim.keymap.set("n", "<leader>dr", "<cmd>lua require'dap'.run_last()<CR>", { desc = "Run Last" })
    vim.keymap.set("n", "<leader>dt", "<cmd>RustLsp testables<CR>", { desc = "Testables" })
    vim.keymap.set("n", "<leader>dD", "<cmd>RustLsp debuggables<CR>", { desc = "Debug Rust Executable" })

    local dap, dapui = require("dap"), require("dapui")
    dap.listeners.before.attach.dapui_config = function() dapui.open() end
    dap.listeners.before.launch.dapui_config = function() dapui.open() end
    dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
    dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

    -- Rust config
    local rust_utils = require("nil.core.utils.rust_root")

    dap.configurations.rust = {
      {
        name = "Debug current file (with input)",
        type = "codelldb",
        request = "launch",
        program = function()
          local root = rust_utils.rust_root()
          -- Grep project name from Cargo.toml
          local cargo_toml = root .. "/Cargo.toml"
          local name = vim.fn.system({ "sh", "-c", "grep '^name' " .. cargo_toml .. " | head -1 | cut -d '\"' -f2" })
          local bin = vim.fn.trim(name ~= "" and name or "main")
          return root .. "/target/debug/" .. bin
        end,
        cwd = rust_utils.rust_root,
        stopOnEntry = false,
        runInTerminal = true,
      },
    }
  end,
}

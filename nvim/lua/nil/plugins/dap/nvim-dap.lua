return {
  "mfussenegger/nvim-dap",
  lazy = false,
  config = function()
    local dap = require("dap")

    -- ╭──────────────────────────────────────────────────────────╮
    -- │ 🚀 Core Debugger Keymaps                                 │
    -- ╰──────────────────────────────────────────────────────────╯
    vim.keymap.set("n", "<leader>dl", dap.step_into, { desc = "Step Into" })
    vim.keymap.set("n", "<leader>dj", dap.step_over, { desc = "Step Over" })
    vim.keymap.set("n", "<leader>dk", dap.step_out, { desc = "Step Out" })
    vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
    vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle Breakpoint" })
    vim.keymap.set("n", "<leader>dd", function()
      dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
    end, { desc = "Conditional Breakpoint" })
    vim.keymap.set("n", "<leader>de", dap.terminate, { desc = "Terminate Debugger" })
    vim.keymap.set("n", "<leader>dr", dap.run_last, { desc = "Run Last Debug Session" })

    -- ╭──────────────────────────────────────────────────────────╮
    -- │ 🐍 Python-specific Keymaps (defined in nvim-dap-python)  │
    -- ╰──────────────────────────────────────────────────────────╯
    vim.keymap.set("n", "<leader>pm", function()
      require("dap-python").test_method()
    end, { desc = "Python: Test Method" })

    vim.keymap.set("n", "<leader>pc", function()
      require("dap-python").test_class()
    end, { desc = "Python: Test Class" })

   -- ╭──────────────────────────────────────────────────────────╮
   -- │ 🐹 Go-specific Keymaps (defined in nvim-dap-go)          │
   -- ╰──────────────────────────────────────────────────────────╯
    vim.keymap.set("n", "<leader>dgt", function()
      require("dap-go").debug_test()
    end, { desc = "Go: Debug Test" })

    vim.keymap.set("n", "<leader>dgl", function()
      require("dap-go").debug_last()
    end, { desc = "Go: Debug Last Test" })

  -- ╭──────────────────────────────────────────────────────────╮
  -- │ 🦀 Rust-specific Keymaps (defined in nvim-dap-rust)      │
  -- ╰──────────────────────────────────────────────────────────╯
    vim.keymap.set("n", "<leader>dt", "<cmd>RustLsp testables<CR>", { desc = "Rust: List Testables" })
    vim.keymap.set("n", "<leader>dD", "<cmd>RustLsp debuggables<CR>", { desc = "Rust: List Debuggables" })
  end,
}


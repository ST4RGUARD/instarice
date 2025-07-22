return {
  "nvim-lua/plenary.nvim",
  ft = "rust",
  dependencies = {
    "mfussenegger/nvim-dap",
  },
  config = function()
    local dap = require("dap")
    local rust_utils = require("nil.core.utils.rust_root")

    dap.configurations.rust = {
      {
        name = "Debug current file (with input)",
        type = "codelldb",
        request = "launch",
        program = function()
          local root = rust_utils.rust_root()
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


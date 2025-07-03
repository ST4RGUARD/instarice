return {
  "mrcjkb/rustaceanvim",
  version = "^5",
  lazy = false,
  config = function()
    local on_attach = require("nil.core.on_attach").common_on_attach
    local capabilities = require("blink.cmp").get_lsp_capabilities()

    local extension_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
    local codelldb_path = extension_path .. "adapter/codelldb"
    local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

    local cfg = require("rustaceanvim.config")

    vim.g.rustaceanvim = {
      server = {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          ["rust-analyzer"] = {
            checkOnSave = true,
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
          },
        },
      },
      dap = {
        adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
      },
    }

    local function cargo_run_in_project_root()
      local buf_path = vim.api.nvim_buf_get_name(0)
      local start_dir = vim.fn.fnamemodify(buf_path, ":p:h")

      local cargo_toml = vim.fn.findfile("Cargo.toml", start_dir .. ";")
      if cargo_toml == "" then
        print("Cargo.toml not found in parent directories")
        return
      end

      local root_dir = vim.fn.fnamemodify(cargo_toml, ":p:h")

      vim.cmd('vsplit')
      vim.cmd('terminal')
      vim.defer_fn(function()
        vim.api.nvim_chan_send(vim.b.terminal_job_id, "cd " .. root_dir .. "\n")
        vim.api.nvim_chan_send(vim.b.terminal_job_id, "cargo run\n")
      end, 100)
    end

    vim.api.nvim_set_keymap('n', '<leader>cr', '', {
      noremap = true,
      silent = true,
      callback = cargo_run_in_project_root,
      desc = "Cargo run in project root",
    })
  end,
}

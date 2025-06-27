return {
  "mrcjkb/rustaceanvim",
  version = "^5",
  lazy = false,
  config = function()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()

    local extension_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
    local codelldb_path = extension_path .. "adapter/codelldb"
    local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

    local cfg = require("rustaceanvim.config")

    vim.g.rustaceanvim = {
      server = {
        capabilities = capabilities,
        on_attach = function(client, bufnr)
          -- Optional keymaps or formatting disable here
        end,
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
      -- Get project root by searching Cargo.toml upwards
      local cwd = vim.fn.getcwd()
      local cargo_root = vim.fn.findfile("Cargo.toml", cwd .. ";")
      if cargo_root == "" then
        print("Cargo.toml not found in parent directories")
        return
      end
      local root_dir = vim.fn.fnamemodify(cargo_root, ":h")

      -- Open vertical split terminal in root dir and run cargo run
      vim.cmd('vsplit')
      vim.cmd('terminal')
      -- Change directory to root_dir
      vim.api.nvim_chan_send(vim.b.terminal_job_id, "cd " .. root_dir .. "\n")
      -- Run cargo run
      vim.api.nvim_chan_send(vim.b.terminal_job_id, "cargo run\n")
    end

    vim.api.nvim_set_keymap('n', '<leader>cr', '', {
      noremap = true,
      silent = true,
      callback = cargo_run_in_project_root,
      desc = "Cargo run in project root",
    })
  end,
}

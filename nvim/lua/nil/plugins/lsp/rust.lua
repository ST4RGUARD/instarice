return {
  'mrcjkb/rustaceanvim',
  version = '^5',
  lazy = false,
  config = function()
    local on_attach = require('nil.core.utils').common_on_attach
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    -- Paths for the debugger (installed via Mason)
    local extension_path = vim.fn.stdpath 'data' .. '/mason/packages/codelldb/extension/'
    local codelldb_path = extension_path .. 'adapter/codelldb'
    local liblldb_path = extension_path .. 'lldb/lib/liblldb.so'

    local cfg = require 'rustaceanvim.config'

    -- Global configuration variable required by rustaceanvim
    vim.g.rustaceanvim = {
      server = {
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          ['rust-analyzer'] = {
            checkOnSave = true,
            check = {
              command = 'clippy',
              extraArgs = { '--no-deps' },
            },
          },
        },
      },
      dap = {
        adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
      },
    }

    -- ╭──────────────────────────────────────────────────────────╮
    -- │ 🚀 Native Cargo Integration                              │
    -- ╰──────────────────────────────────────────────────────────╯
    local rust_utils = require 'nil.core.utils'

    local function cargo_run_in_project_root()
      local root_dir = rust_utils.rust_root()

      vim.cmd 'vsplit'
      vim.cmd 'terminal'
      vim.defer_fn(function()
        vim.api.nvim_chan_send(vim.b.terminal_job_id, 'cd ' .. root_dir .. '\n')
        vim.api.nvim_chan_send(vim.b.terminal_job_id, 'cargo run\n')
      end, 100)
    end

    vim.keymap.set('n', '<leader>cr', cargo_run_in_project_root, {
      silent = true,
      desc = 'Cargo run in project root',
    })
  end,
}

return {
  {
    'mfussenegger/nvim-dap',
    lazy = false,
    dependencies = {
      -- Async UI and extensions
      { 'rcarriga/nvim-dap-ui' },
      { 'nvim-neotest/nvim-nio' },
      { 'leoluz/nvim-dap-go' },
      { 'mfussenegger/nvim-dap-python' },
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'
      local dap_python = require 'dap-python'
      local rust_utils = require 'nil.core.utils'

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ ⚙️ Global UI & Adapter Core Setup                         │
      -- ╰──────────────────────────────────────────────────────────╯
      dapui.setup()
      require('dap-go').setup()

      -- Automatically pop open the UI layouts when debug target launches
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 🐍 Python Adapter & Configuration Logic                  │
      -- ╰──────────────────────────────────────────────────────────╯
      local python_path = vim.fn.getcwd() .. '/.venv/bin/python'
      if vim.fn.executable(python_path) == 0 then
        python_path = vim.fn.exepath 'python3' or vim.fn.exepath 'python'
      end

      if python_path ~= '' then
        dap_python.setup(python_path)
      else
        vim.notify('[dap-python] No python interpreter found!', vim.log.levels.ERROR)
      end

      dap.configurations.python = {
        {
          type = 'python',
          request = 'launch',
          name = 'Debug current Python file',
          program = '${file}',
          console = 'integratedTerminal',
          cwd = function()
            return vim.fn.expand '%:p:h'
          end,
          env = {
            PYTHONPATH = vim.fn.expand '%:p:h',
          },
        },
      }

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 🦀 Rust Cargo Pipeline Configuration                      │
      -- ╰──────────────────────────────────────────────────────────╯
      dap.configurations.rust = {
        {
          name = 'Debug current file (with input)',
          type = 'codelldb',
          request = 'launch',
          program = function()
            local root = rust_utils.rust_root()
            local cargo_toml = root .. '/Cargo.toml'
            local name = vim.fn.system { 'sh', '-c', "grep '^name' " .. cargo_toml .. " | head -1 | cut -d '\"' -f2" }
            local bin = vim.fn.trim(name ~= '' and name or 'main')
            return root .. '/target/debug/' .. bin
          end,
          cwd = rust_utils.rust_root,
          stopOnEntry = false,
          runInTerminal = true,
        },
      }

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 🚀 Core Mappings (Global Execution Matrices)              │
      -- ╰──────────────────────────────────────────────────────────╯
      vim.keymap.set('n', '<leader>dl', dap.step_into, { desc = 'Step Into' })
      vim.keymap.set('n', '<leader>dj', dap.step_over, { desc = 'Step Over' })
      vim.keymap.set('n', '<leader>dk', dap.step_out, { desc = 'Step Out' })
      vim.keymap.set('n', '<leader>dc', dap.continue, { desc = 'Continue' })
      vim.keymap.set('n', '<leader>db', '<cmd>DapToggleBreakpoint<CR>', { desc = 'Toggle Breakpoint' })
      vim.keymap.set('n', '<leader>dd', function()
        dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end, { desc = 'Conditional Breakpoint' })
      vim.keymap.set('n', '<leader>de', dap.terminate, { desc = 'Terminate Debugger' })
      vim.keymap.set('n', '<leader>dr', dap.run_last, { desc = 'Run Last Debug Session' })

      -- UI Toggles
      vim.keymap.set('n', '<leader>du', dapui.toggle, { desc = 'Toggle DAP UI' })
      vim.keymap.set('n', '<leader>dU', dapui.close, { desc = 'Close DAP UI' })

      -- Python Context Keys
      vim.keymap.set('n', '<leader>pm', function()
        require('dap-python').test_method()
      end, { desc = 'Python: Test Method' })
      vim.keymap.set('n', '<leader>pc', function()
        require('dap-python').test_class()
      end, { desc = 'Python: Test Class' })

      -- Go Context Keys
      vim.keymap.set('n', '<leader>dgt', function()
        require('dap-go').debug_test()
      end, { desc = 'Go: Debug Test' })
      vim.keymap.set('n', '<leader>dgl', function()
        require('dap-go').debug_last()
      end, { desc = 'Go: Debug Last Test' })

      -- Rust Context Keys
      vim.keymap.set('n', '<leader>dt', '<cmd>RustLsp testables<CR>', { desc = 'Rust: List Testables' })
      vim.keymap.set('n', '<leader>dD', '<cmd>RustLsp debuggables<CR>', { desc = 'Rust: List Debuggables' })
    end,
  },
}

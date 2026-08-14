return {
  'stevearc/oil.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    local oil = require 'oil'
    local utils = require 'nil.core.utils' -- Centralized utilities engine

    oil.setup {
      default_file_explorer = true,
      reuse_buffers = false,
      columns = {},
      keymaps = {
        ['<C-h>'] = false,
        ['<C-c>'] = false,
        ['<C-l>'] = false,
        ['<C-r>'] = 'actions.refresh',
        ['<M-h>'] = 'actions.select_split',
        ['q'] = 'actions.close',
      },
      delete_to_trash = true,
      view_options = {
        show_hidden = true,
      },
      skip_confirm_for_simple_edits = true,
    }

    -- ╭──────────────────────────────────────────────────────────╮
    -- │ 🚀 Navigation Keymaps                                    │
    -- ╰──────────────────────────────────────────────────────────╯
    vim.keymap.set('n', '-', '<CMD>Oil<CR>', { desc = 'Open parent dir' })

    -- Optimized: Wrapped in a function callback to respect lazy loading structures
    vim.keymap.set('n', '<leader>-', function()
      oil.toggle_float()
    end, { desc = 'Toggle float oil' })

    -- ╭──────────────────────────────────────────────────────────╮
    -- │ 🔄 Automatic Contextual Workspace Sync                    │
    -- ╰──────────────────────────────────────────────────────────╯
    -- Sync working directory to buffer directory whenever you switch/enter a buffer
    vim.api.nvim_create_autocmd('BufEnter', {
      group = vim.api.nvim_create_augroup('OilWorkingDirSync', { clear = true }),
      callback = function()
        -- 1. Ignore terminal buffers to prevent E472 errors
        if vim.bo.buftype == 'terminal' then
          return
        end

        local dir = utils.get_buffer_dir()

        -- 2. Use pcall to safely execute the window-local change command
        if dir and dir ~= '' then
          pcall(vim.cmd, 'lcd ' .. vim.fn.fnameescape(dir))
        end
      end,
    })

    -- ╭──────────────────────────────────────────────────────────╮
    -- │ 💻 Contextual Terminal Command                           │
    -- ╰──────────────────────────────────────────────────────────╯
    vim.api.nvim_create_user_command('Term', function()
      local dir = utils.get_buffer_dir()
      if dir and dir ~= '' then
        vim.cmd('lcd ' .. vim.fn.fnameescape(dir))
      end
      vim.cmd 'terminal'
    end, {})
  end,
}

return {
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      { 'nvim-tree/nvim-web-devicons' },
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
      { 'jvgrootveld/telescope-zoxide' },
    },

    config = function()
      local telescope = require 'telescope'
      local actions = require 'telescope.actions'
      local action_state = require 'telescope.actions.state'
      local builtin = require 'telescope.builtin'
      local path = require 'nil.core.utils'

      telescope.setup {
        defaults = {
          path_display = { 'smart' },
          mappings = {
            i = {
              ['<C-k>'] = actions.move_selection_previous,
              ['<C-j>'] = actions.move_selection_next,
            },
          },
        },
      }

      telescope.load_extension 'fzf'
      telescope.load_extension 'zoxide'

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 📂 Zoxide Directory Jump -> Oil                           │
      -- ╰──────────────────────────────────────────────────────────╯
      local function open_zoxide()
        telescope.extensions.zoxide.list {
          attach_mappings = function(prompt_bufnr, map)
            local function jump()
              local entry = action_state.get_selected_entry()

              if not entry then
                return
              end

              actions.close(prompt_bufnr)

              vim.schedule(function()
                vim.cmd('edit ' .. vim.fn.fnameescape(entry.path))
              end)
            end

            map('i', '<CR>', jump)
            map('n', '<CR>', jump)

            return true
          end,
        }
      end

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 🔎 Oil Contextual Live Grep                              │
      -- ╰──────────────────────────────────────────────────────────╯
      vim.keymap.set('n', '<leader>/', function()
        local word = vim.fn.expand '<cWORD'

        builtin.live_grep {
          search = word,
          cwd = path.get_buffer_dir(),
        }
      end, { desc = 'Oil Grep' })

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 🚀 Global Navigation Mappings                            │
      -- ╰──────────────────────────────────────────────────────────╯
      vim.keymap.set('n', '<leader>z', open_zoxide, {
        desc = 'Zoxide Directory Jump',
      })

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 📂 Empty Workspace Auto-Trigger                          │
      -- ╰──────────────────────────────────────────────────────────╯
      vim.api.nvim_create_autocmd('VimEnter', {
        group = vim.api.nvim_create_augroup('TelescopeZoxideAutostart', { clear = true }),
        callback = function()
          if vim.fn.argc() == 0 then
            open_zoxide()
          end
        end,
      })
    end,
  },
}

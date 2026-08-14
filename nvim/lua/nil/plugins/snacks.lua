return {
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    opts = {
      terminal = {
        enabled = true,
        auto_insert = false,
        win = {
          style = 'terminal',
          position = 'float',
          border = 'rounded',
          backdrop = false,
          width = 100,
          height = 20,
          -- 1. Strip out the solid background color highlights
          hl = {
            Normal = 'NormalFloat',
            FloatBorder = 'FloatBorder',
          },
          -- 2. Apply the window blend options to those transparent highlights
          wo = {
            winblend = 15,
          },
        },
      },
      explorer = {
        enabled = true,
        layout = { cycle = false },
      },
      quickFile = {
        enabled = true,
        exclude = { 'latex' },
      },
      picker = {
        enabled = true,
        matchers = {
          frecency = true,
          cwd_bonus = true,
        },
        formatters = {
          file = {
            filename_first = false,
            filename_only = false,
            icon_width = 2,
          },
        },
        layout = {
          preset = 'telescope',
          cycle = false,
        },
        layouts = {
          select = {
            preview = false,
            layout = {
              backdrop = false,
              width = 0.6,
              min_width = 80,
              height = 0.4,
              min_height = 10,
              box = 'vertical',
              border = 'rounded',
              title = '{title}',
              title_pos = 'center',
              { win = 'input', height = 1, border = 'bottom' },
              { win = 'list', border = 'none' },
              { win = 'preview', title = '{preview}', width = 0.6, height = 0.4, border = 'top' },
            },
          },
          telescope = {
            reverse = true,
            layout = {
              box = 'horizontal',
              backdrop = false,
              width = 0.8,
              height = 0.9,
              border = 'none',
              {
                box = 'vertical',
                { win = 'list', title = ' Results ', title_pos = 'center', border = 'rounded' },
                { win = 'input', height = 1, border = 'rounded', title = '{title} {live} {flags}', title_pos = 'center' },
              },
            },
          },
          ivy = {
            layout = {
              box = 'vertical',
              backdrop = false,
              width = 0,
              height = 0.4,
              position = 'bottom',
              border = 'top',
              title = ' {title} {live} {flags} ',
              title_pos = 'left',
              { win = 'input', height = 1, border = 'bottom' },
              {
                box = 'horizontal',
                { win = 'list', border = 'none' },
                { win = 'preview', title = '{preview}', width = 0.5, border = 'left' },
              },
            },
          },
        },
      },
      image = {
        enabled = true,
        doc = {
          float = false,
          inline = true,
          max_width = 50,
          max_height = 30,
          wo = { wrap = true },
        },
        convert = {
          notify = true,
          command = 'magick',
        },
        img_dirs = { 'assets' },
      },
      dashboard = { enabled = false },
    },

    keys = function()
      local buffer_dir = require 'nil.core.utils'

      return {
        -- 2. REPLICATING YOUR EXACT TOGGLETERM KEYMAP LOGIC
        -- Global Float Toggle (Ctrl + \)
        {
          [[<C-\>]],
          function()
            require('snacks').terminal.toggle()
          end,
          desc = 'Toggle Terminal',
          mode = { 'n', 't' },
        },

        -- Float Toggle Scoped Directly to Current Buffer's Active Directory
        {
          '<leader>ts',
          function()
            require('snacks').terminal.toggle(nil, { cwd = buffer_dir.get_buffer_dir() })
          end,
          desc = 'Toggle Float Term in Buffer Dir',
        },

        -- Your existing snacks mappings
        {
          '<leader>lg',
          function()
            require('snacks').lazygit()
          end,
          desc = 'Lazygit',
        },
        {
          '<leader>gl',
          function()
            require('snacks').lazygit.log()
          end,
          desc = 'Lazygit Logs',
        },
        {
          '<leader>es',
          function()
            require('snacks').explorer()
          end,
          desc = 'Open Snacks Explorer',
        },
        {
          '<leader>rN',
          function()
            require('snacks').rename.rename_file()
          end,
          desc = 'Fast Rename File',
        },
        {
          '<leader>dB',
          function()
            require('snacks').bufdelete()
          end,
          desc = 'Delete or Close Buffer',
        },

        {
          '<leader>pf',
          function()
            require('snacks').picker.files { cwd = buffer_dir.get_buffer_dir() }
          end,
          desc = 'Find Files',
        },
        {
          '<leader>ps',
          function()
            require('snacks').picker.grep { cwd = buffer_dir.get_buffer_dir() }
          end,
          desc = 'Grep Word',
        },
        {
          '<leader>pws',
          function()
            require('snacks').picker.grep_word { cwd = buffer_dir.get_buffer_dir() }
          end,
          desc = 'Grep Visual Selection, or Word',
          mode = { 'n', 'x' },
        },
        {
          '<leader>pk',
          function()
            require('snacks').picker.keymaps { layout = 'ivy' }
          end,
          desc = 'Search Keymaps',
        },

        {
          '<leader>gbr',
          function()
            require('snacks').picker.git_branches { layout = 'select' }
          end,
          desc = 'Pick and Switch Git Branches',
        },
        {
          '<leader>th',
          function()
            require('snacks').picker.colorschemes { layout = 'ivy' }
          end,
          desc = 'Pick Colorschemes',
        },
        {
          '<leader>vh',
          function()
            require('snacks').picker.help()
          end,
          desc = 'Help Pages',
        },
      }
    end,
  },
}

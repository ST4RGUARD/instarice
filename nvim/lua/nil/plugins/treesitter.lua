return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    event = { 'BufReadPre', 'BufNewFile' },
    build = ':TSUpdate',
    dependencies = {
      { 'RRethy/nvim-treesitter-endwise' },
      { 'windwp/nvim-ts-autotag' },
    },
    config = function()
      -- Native filetype additions
      vim.filetype.add {
        extension = { odin = 'odin' },
      }

      -- FIX: Changed from .configs to .config to match your original working setup
      require('nvim-treesitter.config').setup {
        ensure_installed = {
          'json',
          'asm',
          'javascript',
          'xml',
          'ruby',
          'tcl',
          'rust',
          'typescript',
          'tsx',
          'go',
          'yaml',
          'html',
          'css',
          'python',
          'http',
          'prisma',
          'markdown',
          'markdown_inline',
          'svelte',
          'graphql',
          'bash',
          'lua',
          'vim',
          'dockerfile',
          'gitignore',
          'query',
          'vimdoc',
          'c',
          'cpp',
          'r',
          'java',
          'odin',
        },
        auto_install = true,

        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },

        indent = { enable = true },

        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = '<C-space>',
            node_incremental = '<C-space>',
            scope_incremental = false,
          },
        },

        endwise = { enable = true },
      }

      -- Intelligent HTML/JSX/TSX Close & Auto-Rename
      require('nvim-ts-autotag').setup {
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = false,
        },
        per_filetype = {
          ['html'] = { enable_close = true },
          ['typescriptreact'] = { enable_close = true },
        },
      }
    end,
  },
}

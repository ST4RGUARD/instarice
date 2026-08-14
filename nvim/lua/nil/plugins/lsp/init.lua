return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      -- Mason Core & Installation Tooling
      { 'williamboman/mason.nvim' },
      { 'williamboman/mason-lspconfig.nvim' },
      { 'WhoIsSethDaniel/mason-tool-installer.nvim' },

      -- Formatting Engine
      { 'stevearc/conform.nvim' },

      -- Complementary Features
      { 'saghen/blink.cmp' },
      { 'antosha417/nvim-lsp-file-operations', config = true },
    },
    config = function()
      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 🔨 Part 1: Mason Setup & Tool Sync                       │
      -- ╰──────────────────────────────────────────────────────────╯
      require('mason').setup {
        ui = {
          icons = {
            package_installed = '✓',
            package_pending = '➜',
            package_uninstalled = '✗',
          },
        },
      }

      require('mason-lspconfig').setup {
        ensure_installed = {
          'lua_ls',
          'html',
          'cssls',
          'clangd',
          'denols',
          'jsonls',
          'pyright',
          'emmet_ls',
          'marksman',
          'gopls',
          'ts_ls',
        },
        automatic_installation = true,
      }

      require('mason-tool-installer').setup {
        ensure_installed = {
          'stylua',
          'black',
          'isort',
          'clang-format',
          'pylint',
          'eslint_d',
          'debugpy',
          'codelldb',
          'delve',
        },
        auto_update = false,
        run_on_start = true,
      }

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 🧼 Part 2: Code Formatting Setup (Conform)               │
      -- ╰──────────────────────────────────────────────────────────╯
      local conform = require 'conform'

      conform.setup {
        formatters = {
          ['markdown-toc'] = {
            condition = function(_, ctx)
              for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
                if line:find '<!%-%- toc %-%->' then
                  return true
                end
              end
            end,
          },
          ['markdownlint-cli2'] = {
            condition = function(_, ctx)
              local diag = vim.tbl_filter(function(d)
                return d.source == 'markdownlint'
              end, vim.diagnostic.get(ctx.buf))
              return #diag > 0
            end,
          },
        },
        formatters_by_ft = {
          javascript = { 'prettier' },
          typescript = { 'prettier' },
          javascriptreact = { 'prettier' },
          typescriptreact = { 'prettier' },
          svelte = { 'prettier' },
          css = { 'prettier' },
          html = { 'prettier' },
          json = { 'prettier' },
          yaml = { 'prettier' },
          graphql = { 'prettier' },
          liquid = { 'prettier' },
          lua = { 'stylua' },
          python = { 'black' },
          c = { 'clang_format' },
          cpp = { 'clang_format' },
          markdown = { 'prettier' },
          ['markdown.mdx'] = { 'prettier', 'markdownlint-cli2', 'markdown-toc' },
        },
      }

      conform.formatters.prettier = {
        args = {
          '--stdin-filepath',
          '$FILENAME',
          '--tab-width',
          '2',
          '--use-tabs',
          'false',
        },
      }

      conform.formatters.shfmt = {
        prepend_args = { '-i', '2' },
      }

      -- Format File or Selection Keymap
      vim.keymap.set({ 'n', 'v' }, '<leader>mp', function()
        conform.format {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        }
      end, { desc = 'Prettier Format whole file or range (in visual mode)' })

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 🚀 Part 3: LSP Client Configuration Matrix               │
      -- ╰──────────────────────────────────────────────────────────╯
      local capabilities = require('blink.cmp').get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
      local on_attach = require('nil.core.utils').common_on_attach
      local mason_lspconfig = require 'mason-lspconfig'

      local manual_servers = {
        ruby_lsp = true,
        rust_analyzer = true,
      }

      local servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { 'vim' } },
              completion = { callSnippet = 'Replace' },
              workspace = {
                library = {
                  [vim.fn.expand '$VIMRUNTIME/lua'] = true,
                  [vim.fn.stdpath 'config' .. '/lua'] = true,
                },
              },
            },
          },
        },
      }

      -- Auto-configure servers managed by Mason
      local installed_servers = mason_lspconfig.get_installed_servers()
      for _, server_name in ipairs(installed_servers) do
        if not manual_servers[server_name] then
          local opts = {
            on_attach = on_attach,
            capabilities = capabilities,
          }

          if servers[server_name] then
            opts = vim.tbl_deep_extend('force', opts, servers[server_name])
          end

          vim.lsp.config(server_name, opts)
          vim.lsp.enable(server_name)
        end
      end

      -- ╭──────────────────────────────────────────────────────────╮
      -- │ 💎 Part 4: ruby_lsp - using mise                         │
      -- ╰──────────────────────────────────────────────────────────╯
      vim.lsp.config('ruby_lsp', {
        cmd = {
          'ruby-lsp',
        },
        on_attach = on_attach,
        capabilities = capabilities,
      })

      vim.lsp.enable 'ruby_lsp'
    end,
  },
}

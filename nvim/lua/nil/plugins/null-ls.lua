return {
  "nvimtools/none-ls.nvim",
  dependencies = {
    "nvimtools/none-ls-extras.nvim",
    "jayp0521/mason-null-ls.nvim",
  },
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local null_ls = require("null-ls")

    require("mason-null-ls").setup({
      ensure_installed = { "rubocop", "rubyfmt", "ruff", "prettier" },
      automatic_installation = true,
    })

    null_ls.setup({
      sources = {
        -- Ruby formatting using rubyfmt
        null_ls.builtins.formatting.rubyfmt.with({
          command = vim.fn.stdpath("data") .. "/mason/bin/rubyfmt",
        }),

        -- Python formatting with ruff (format + lint)
        require("none-ls.formatting.ruff").with({ extra_args = { "--extend-select", "I" } }),
        require("none-ls.formatting.ruff_format"),

        -- Go formatting tools
        null_ls.builtins.formatting.gofumpt,
        null_ls.builtins.formatting.goimports_reviser,
        null_ls.builtins.formatting.golines,

        -- Prettier formatting for json, yaml, markdown
        null_ls.builtins.formatting.prettier.with({
          filetypes = { "json", "yaml", "markdown" },
        }),

        -- Formatter for C/C++
        null_ls.builtins.formatting.clang_format.with({
          command = "~/.local/share/nvim/mason/bin/clang-format",
        }),

      },

      on_attach = function(client, bufnr)
        if client.supports_method("textDocument/formatting") then
          local augroup = vim.api.nvim_create_augroup("LspFormatting", { clear = true })

          vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
              vim.lsp.buf.format({
                bufnr = bufnr,
                async = false,
                timeout_ms = 5000,
                filter = function(c)
                  return c.name == "null-ls"
                end,
              })
            end,
          })
        end
      end,
    })
  end,
}

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "saghen/blink.cmp",
    { "antosha417/nvim-lsp-file-operations", config = true },
  },
  config = function()
    local lspconfig = require("lspconfig")
    local util = lspconfig.util
    local capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
    local on_attach = require("nil.core.on_attach").common_on_attach

    -- Diagnostic icons and config here (keep as before)...

    local servers = {
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            completion = { callSnippet = "Replace" },
            workspace = {
              library = {
                [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                [vim.fn.stdpath("config") .. "/lua"] = true,
              },
            },
          },
        },
      },
      -- other servers here ...
    }

    require("mason").setup()
    local mason_lspconfig = require("mason-lspconfig")
    mason_lspconfig.setup({
      ensure_installed = { "lua_ls", "gopls", "ts_ls", "emmet_ls", "denols" },
      automatic_installation = true,
    })

    mason_lspconfig.setup_handlers {
      function(server_name) -- default handler
        local opts = {
          on_attach = on_attach,
          capabilities = capabilities,
        }
        if servers[server_name] then
          opts = vim.tbl_deep_extend("force", opts, servers[server_name])
        end
        lspconfig[server_name].setup(opts)
      end,
    }
  end,
}

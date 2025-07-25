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
    local capabilities = require("blink.cmp").get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
    local on_attach = require("nil.core.utils.on_attach").common_on_attach
    local mason_lspconfig = require("mason-lspconfig")

    local home = os.getenv("HOME")
    local ruby_root = home .. "/.frum/versions/3.4.4/bin"

    -- LSP configurations for manually handled servers
    local manual_servers = {
      ruby_lsp = true,      -- We're setting this up manually
      rust_analyzer = true, -- Rustaceanvim handles this
    }

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
    }

    -- Setup all installed Mason LSP servers unless manually excluded
    local installed_servers = mason_lspconfig.get_installed_servers()

    for _, server_name in ipairs(installed_servers) do
      if not manual_servers[server_name] then
        local opts = {
          on_attach = on_attach,
          capabilities = capabilities,
        }

        if servers[server_name] then
          opts = vim.tbl_deep_extend("force", opts, servers[server_name])
        end

        lspconfig[server_name].setup(opts)
      end
    end

    -- Explicit ruby_lsp setup (using frum path)
    lspconfig.ruby_lsp.setup({
      cmd = {
        ruby_root .. "/ruby",
        ruby_root .. "/ruby-lsp",
      },
      cmd_env = {
        PATH = ruby_root .. ":" .. vim.env.PATH,
        GEM_HOME = os.getenv("GEM_HOME"),
        GEM_PATH = os.getenv("GEM_PATH"),
      },
      on_attach = on_attach,
      capabilities = capabilities,
    })
  end,
}

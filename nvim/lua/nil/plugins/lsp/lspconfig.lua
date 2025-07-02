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

    local on_attach = function(client, bufnr)
      local opts = { buffer = bufnr, silent = true }

      if client.name == "gopls" then
        client.server_capabilities.documentFormattingProvider = false
      end

      opts.desc = "Show LSP references"
      vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

      opts.desc = "Go to declaration"
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

      opts.desc = "Show LSP definitions"
      vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

      opts.desc = "Show LSP implementations"
      vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

      opts.desc = "Show LSP type definitions"
      vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

      opts.desc = "See available code actions"
      vim.keymap.set({ "n", "v" }, "<leader>vca", vim.lsp.buf.code_action, opts)

      opts.desc = "Smart rename"
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

      opts.desc = "Show buffer diagnostics"
      vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

      opts.desc = "Show line diagnostics"
      vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

      opts.desc = "Show documentation for what is under cursor"
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

      opts.desc = "Restart LSP"
      vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

      vim.keymap.set("i", "<C-h>", vim.lsp.buf.signature_help, opts)
    end

    -- Diagnostic icons
    local signs = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN]  = " ",
      [vim.diagnostic.severity.HINT]  = "󰠠 ",
      [vim.diagnostic.severity.INFO]  = " ",
    }
    vim.diagnostic.config({
      signs = { text = signs },
      virtual_text = true,
      underline = true,
      update_in_insert = false,
    })

    -- Mason-managed LSP servers with custom settings
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
      gopls = {
        cmd = { "gopls" },
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        root_dir = util.root_pattern("go.work", "go.mod", ".git"),
        settings = {
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
          },
        },
      },
      emmet_ls = {
        filetypes = {
          "html", "typescriptreact", "javascriptreact",
          "css", "sass", "scss", "less", "svelte",
        },
      },
      denols = {
        root_dir = util.root_pattern("deno.json", "deno.jsonc"),
      },
      ts_ls = {
        root_dir = function(fname)
          return not util.root_pattern("deno.json", "deno.jsonc")(fname)
              and util.root_pattern("tsconfig.json", "package.json", "jsconfig.json", ".git")(fname)
        end,
        single_file_support = false,
        init_options = {
          preferences = {
            includeCompletionsWithSnippetText = true,
            includeCompletionsForImportStatements = true,
          },
        },
      },
    }

    -- Setup via mason-lspconfig auto integration

 require("mason").setup()
    local mason_lspconfig = require("mason-lspconfig")
    mason_lspconfig.setup()

    for server_name, server_opts in pairs(servers) do
      local opts = {
        on_attach = on_attach,
        capabilities = capabilities,
      }
      for k, v in pairs(server_opts) do
        if type(opts[k]) == "table" and type(v) == "table" then
          opts[k] = vim.tbl_deep_extend("force", opts[k], v)
        else
          opts[k] = v
        end
      end
      lspconfig[server_name].setup(opts)
    end
  end,
}

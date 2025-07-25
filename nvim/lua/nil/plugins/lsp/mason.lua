return {
  "williamboman/mason.nvim",
  lazy = false,
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    local mason = require("mason")
    local mason_lspconfig = require("mason-lspconfig")
    local mason_tool_installer = require("mason-tool-installer")

    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    mason_lspconfig.setup({
      ensure_installed = {
        "lua_ls",
        "html",
        "cssls",
        "clangd",
        "denols",
        "jsonls",
        "pyright",
        "emmet_ls",
        "marksman",
        "gopls",
        "ts_ls",
      },
      automatic_installation = true,
    })

    mason_tool_installer.setup({
      ensure_installed = {
        "stylua",
        "black",
        "isort",
        "clang-format",
        "pylint",
        "eslint_d",
        "debugpy",
        "codelldb",
        "delve",
      },
      auto_update = false,
      run_on_start = true,
    })
  end,
}

return {
    "williamboman/mason.nvim",
    lazy = false,
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "neovim/nvim-lspconfig",
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
                -- LSP servers only
                "lua_ls",
                "html",
                "cssls",
                "clangd",
                "denols",
                "jsonls",
                "pyright",
                "rust_analyzer",
                "emmet_ls",
                "marksman",
                "ruby_lsp",
                "gopls",
            },
        })

        mason_tool_installer.setup({
            ensure_installed = {
                -- Formatters
                "stylua",     -- Lua
                "prettier",   -- JS/TS/HTML/CSS
                "black",      -- Python
                "isort",      -- Python
                "rubocop",    -- Ruby
                "clang-format", -- C/C++

                -- Linters
                "pylint",     -- Python
                "eslint_d",   -- JS/TS
                "ruff",       -- Python (alternative linter)

                -- Debuggers
                "debugpy",    -- Python
                "codelldb",   -- C/C++/Rust
                "delve",      -- Go
            },
            auto_update = false,
            run_on_start = true,
        })
    end,
}

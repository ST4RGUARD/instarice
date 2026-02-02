return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    dependencies = {
      "RRethy/nvim-treesitter-endwise",
      "andymass/vim-matchup",
    },
    config = function()
      local treesitter = require("nvim-treesitter")

      treesitter.setup({
        ensure_installed = {
          "json", "asm", "javascript", "xml", "ruby", "tcl", "rust",
          "typescript", "tsx", "go", "yaml", "html", "css", "python",
          "http", "prisma", "markdown", "markdown_inline", "svelte",
          "graphql", "bash", "lua", "vim", "dockerfile", "gitignore",
          "query", "vimdoc", "c", "cpp", "r", "java",
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
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
          },
        },

        endwise = { enable = true },

        matchup = { enable = true }, -- enables vim-matchup integration
      })

      -- Optional: Improve vim-matchup popup behavior
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },

  -- Auto close/rename HTML/JSX tags
  {
    "windwp/nvim-ts-autotag",
    ft = {
      "html", "xml", "javascript", "typescript", "javascriptreact",
      "typescriptreact", "svelte", "markdown", "markdown_inline",
    },
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          enable_close = true,
          enable_rename = true,
          enable_close_on_slash = false,
        },
        per_filetype = {
          ["html"] = { enable_close = true },
          ["typescriptreact"] = { enable_close = true },
        },
      })
    end,
  },
}

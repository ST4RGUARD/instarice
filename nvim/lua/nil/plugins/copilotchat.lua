return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "github/copilot.vim" }, -- or zbirenbaum/copilot.lua
      { "nvim-lua/plenary.nvim", branch = "master" }, -- for curl, log and async functions
    },
    build = "make tiktoken",
    event = "InsertEnter",
    opts = {
      -- See Configuration section for options
    },
    -- See Commands section for default commands if you want to lazy load on them
    keys = {
      { "<leader>xc", ":CopilotChat<CR>", mode = "n", desc = "Chat with Copilot" },
      { "<leader>xe", ":CopilotChatExplain<CR>", mode = "v", desc = "Explain Code" },
      { "<leader>xr", ":CopilotChatReview<CR>", mode = "v", desc = "Review Code" },
      { "<leader>xf", ":CopilotChatFix<CR>", mode = "v", desc = "Fix Code Issues" },
      { "<leader>xo", ":CopilotChatOptimize<CR>", mode = "v", desc = "Optimize Code" },
    }
  },
}

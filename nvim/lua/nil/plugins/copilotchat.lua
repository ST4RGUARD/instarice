return {
  {
    'CopilotC-Nvim/CopilotChat.nvim',
    dependencies = {
      {
        'github/copilot.vim',
        lazy = false,
        config = function()
          vim.g.copilot_no_tab_map = true
          vim.g.copilot_assume_mapped = true
          vim.g.copilot_enabled = 1
        end,
      },
      {
        'nvim-lua/plenary.nvim',
        branch = 'master',
      },
    },

    build = 'make tiktoken',

    opts = {},

    keys = {
      { '<leader>xc', ':CopilotChat<CR>', mode = 'n', desc = 'Chat with Copilot' },
      { '<leader>xe', ':CopilotChatExplain<CR>', mode = 'v', desc = 'Explain Code' },
      { '<leader>xr', ':CopilotChatReview<CR>', mode = 'v', desc = 'Review Code' },
      { '<leader>cf', ':CopilotChatFix<CR>', mode = 'v', desc = 'Fix Code Issues' },
      { '<leader>rf', ':CopilotChatOptimize<CR>', mode = 'v', desc = 'Optimize Code' },

      {
        '<leader>ct',
        function()
          if vim.g.copilot_enabled == 1 then
            vim.cmd 'Copilot disable'
            vim.g.copilot_enabled = 0
          else
            vim.cmd 'Copilot enable'
            vim.g.copilot_enabled = 1
          end
        end,
        mode = 'n',
        desc = 'Toggle Copilot Completion',
      },
    },
  },
}

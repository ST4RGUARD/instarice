return {
  {
    dir = '~/git/omnivision',
    name = 'omnivision',

    config = function()
      require('omnivision').setup()

      local map = vim.keymap.set

      map('n', '<leader>o', '<cmd>OmniVisionEvalLine<CR>', { desc = 'OmniVision Eval Line' })
      map('v', '<leader>os', '<cmd>OmniVisionEvalSelection<CR>', { desc = 'OmniVision Eval Selection' })
      map('n', '<leader>ob', '<cmd>OmniVisionEvalBuffer<CR>', { desc = 'OmniVision Eval Buffer' })

      map('n', '<leader>ou', '<cmd>OmniVisionUndo<CR>', { desc = 'OmniVision Undo' })
      map('n', '<leader>oc', '<cmd>OmniVisionClear<CR>', { desc = 'OmniVision Clear' })
      map('n', '<leader>od', '<cmd>OmniVisionClearBuffer<CR>', { desc = 'OmniVision Clear Buffer' })
      map('n', '<leader>or', '<cmd>OmniVisionReload<CR>', { desc = 'OmniVision Reload' })

      map('n', '<leader>ot', '<cmd>OmniVisionToggleRunner<CR>', { desc = 'OmniVision Toggle Runner' })
    end,
  },
}

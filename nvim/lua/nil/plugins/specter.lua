return {
  dir = vim.fn.stdpath 'config' .. '/lua/nil/specter',

  name = 'specter',

  config = function()
    require('nil.specter.init').setup {
      chat_model = 'claude-opus-4-5',
      refactor_model = 'claude-sonnet-4-6',
    }
  end,
}

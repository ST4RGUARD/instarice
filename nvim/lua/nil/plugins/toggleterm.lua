return {
  'akinsho/toggleterm.nvim',
  version = '*',
  config = function()
    local toggleterm = require("toggleterm")
    local Terminal = require("toggleterm.terminal").Terminal

    toggleterm.setup({
      size = 10,
      open_mapping = [[<C-\>]],
      direction = "float",
      float_opts = {
        width = 100,
        height = 20,
        border = "curved",
        winblend = 0,
      },
      shade_terminals = true,
      start_in_insert = true,
      persist_size = true,
    })

    local function get_current_buffer_dir()
      return require("nil.core.utils.buffer_dir").get_buffer_dir()
    end

    vim.keymap.set('n', '<leader>ts', function()
      local dir = get_current_buffer_dir()

      local term = Terminal:new({
        dir = dir, -- << this sets the CWD of the terminal
        direction = "float",
        on_open = function(term)
          vim.cmd("startinsert!")
        end,
      })

      term:toggle()
    end, { desc = 'Toggle float term in buffer dir' })
  end,
}

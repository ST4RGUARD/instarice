return {
  'saecki/crates.nvim',
  tag = 'stable',
  event = { 'BufRead Cargo.toml' },
  dependencies = { 'saghen/blink.cmp' }, -- Ensure blink is declared as a dependency
  config = function()
    require('crates').setup {
      completion = {
        blink = {
          enable = true,
        },
        cmp = {
          enabled = false,
        },
      },
    }
  end,
}

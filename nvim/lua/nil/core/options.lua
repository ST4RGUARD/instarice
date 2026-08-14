vim.cmd 'let g:netrw_banner = 0'

vim.opt.guicursor = ''
vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.showbreak = '↪ '

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = vim.fn.stdpath 'config' .. '/undodir'
vim.opt.undofile = true
vim.opt.incsearch = true
vim.opt.inccommand = 'split'
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank { higroup = 'IncSearch', timeout = 200 }
  end,
})

vim.opt.termguicolors = true
vim.opt.background = 'dark'
vim.opt.scrolloff = 8
vim.opt.signcolumn = 'yes'

vim.opt.backspace = { 'start', 'eol', 'indent' }

vim.opt.splitright = true
vim.opt.splitbelow = true
vim.colorcolunmn = '80'

vim.opt.clipboard:append 'unnamedplus'
vim.opt.hlsearch = true

vim.opt.mouse = 'a'
vim.g.editorconfig = true

vim.cmd 'colorscheme onedarkOLED'
vim.opt.ttimeout = true
vim.opt.ttimeoutlen = 10

-- Force Neovim's floating windows and borders to be completely see-through
vim.api.nvim_set_hl(0, 'NormalFloat', { bg = 'NONE', ctermbg = 'NONE' })
vim.api.nvim_set_hl(0, 'FloatBorder', { bg = 'NONE', ctermbg = 'NONE' })
vim.api.nvim_set_hl(0, 'SnacksNormal', { bg = 'NONE', ctermbg = 'NONE' })

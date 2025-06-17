local opts = {noremap = true, silent = true}

vim.g.mapleader = ","
vim.g.maplocaleader = ","

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })

vim.keymap.set("v", ">", ">gv", opts)
vim.keymap.set("v", "<", "<gv", opts)

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("n", "x", '"_x', opts)

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word cursor is on globally" })

-- split
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "split window equally" })
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "close split" })
vim.keymap.set('n', '<leader>shr', ':resize 30<CR>', { desc = 'Resize horizontal split to 30 lines' })

-- jump between windows
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

local diagnostics_enabled = true

function ToggleDiagnostics()
    diagnostics_enabled = not diagnostics_enabled
    if diagnostics_enabled then
        vim.diagnostic.enable()
        print("Diagnostics enabled")
    else
        vim.diagnostic.enable(false)
        print("Diagnostics disabled")
    end
end

-- Keybinding: Change <leader>d to your preferred key combo
vim.keymap.set('n', '<leader>dX', ToggleDiagnostics, { noremap = true, silent = true, desc = "Toggle diagnostics" })

local opts = { noremap = true, silent = true }

vim.g.mapleader = ","
vim.g.maplocaleader = ","

vim.keymap.set('t', '<Esc>', [[<C-\><C-n>]], { noremap = true })
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "moves lines down in visual selection" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "moves lines up in visual selection" })

vim.keymap.set("v", ">", ">gv", opts)
vim.keymap.set("v", "<", "<gv", opts)

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("n", "x", '"_x', opts)

vim.keymap.set("n", "<C-c>", ":nohl<CR>", { desc = "Clear search hl", silent = true })

vim.keymap.set('i', '<C-a>', 'copilot#Accept("\\<CR>")', { expr = true, silent = true, replace_keycodes = false, desc = 'Copilot: Accept suggestion' })

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)

vim.keymap.set('n', '<leader>br', function()
  -- Open a vertical split and open a terminal there running 'bun run %'
  vim.cmd('vsplit')
  vim.cmd('terminal bun run ' .. vim.fn.expand('%'))
end, { noremap = true, silent = true })

-- c / cpp run
vim.api.nvim_set_keymap(
  "n",
  "<leader>r",
  [[:w<CR>:vsplit | terminal cd %:p:h && g++ -std=c++23 % -o %:t:r; echo 'g++ % -o %:t:r'; exec zsh<CR>]],
  { noremap = true, silent = true }
)

vim.keymap.set("n", "<leader>rh", function()
  local dir = vim.fn.expand("%:p:h")
  local files = vim.fn.glob(dir .. "/*.c", false, true)
  vim.list_extend(files, vim.fn.glob(dir .. "/*.cpp", false, true))
  local out = vim.fn.expand("%:t:r")
  local cmd = "g++ " .. table.concat(files, " ") .. " -o " .. out
  local basenames = {}
  for _, f in ipairs(files) do
    table.insert(basenames, vim.fn.fnamemodify(f, ":t"))
  end
  local echo_cmd = "g++ -std=c++23 " .. table.concat(basenames, " ") .. " -o " .. out
  vim.cmd("vsplit | terminal cd " .. dir .. " && echo '" .. echo_cmd .. "' && " .. cmd .. "; exec zsh")
end, { noremap = true, silent = true, desc = "Compile and link all .c/.cpp files in dir" })

-- replace
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = "Replace word cursor is on globally" })

vim.keymap.set("v", "<leader>j", function()
  -- Get visual selection
  local _, lsrow, lscol, _ = unpack(vim.fn.getpos("'<"))
  local _, lerow, lecol, _ = unpack(vim.fn.getpos("'>"))
  local lines = vim.fn.getline(lsrow, lerow)
  if #lines == 0 then return end

  lines[#lines] = string.sub(lines[#lines], 1, lecol)
  lines[1] = string.sub(lines[1], lscol)
  local selection = table.concat(lines, "\n")
  selection = vim.fn.escape(selection, '/\\')

  -- Prompt for replacement
  local replacement = vim.fn.input("Replace with: ")

  -- Set arglist to files in current dir only (not recursive)
  vim.cmd("args `find . -maxdepth 1 -type f`")

  -- Perform the substitution
  vim.cmd("argdo %s/" .. selection .. "/" .. replacement .. "/g | update")
end, { desc = "Replace visual selection across current dir files" })

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

-- disable Diagnostics
vim.keymap.set('n', '<leader>dX', ToggleDiagnostics, { noremap = true, silent = true, desc = "Toggle diagnostics" })


-- convert .ipynb Jupyter Notebook to Python with jupytext
vim.keymap.set("n", "<leader>jc", function()
  local input = vim.fn.expand("%:p")
  local ext = vim.fn.expand("%:e")

  if ext ~= "ipynb" then
    vim.notify("Not a .ipynb file", vim.log.levels.WARN)
    return
  end

  local output = vim.fn.expand("%:r") .. ".py"
  local cmd = string.format("jupytext --to py:percent --opt comment_magics=false %s -o %s", input, output)

  vim.fn.jobstart(cmd, {
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("Converted to " .. output, vim.log.levels.INFO)
        vim.cmd("edit " .. output)
      else
        vim.notify("Conversion failed", vim.log.levels.ERROR)
      end
    end
  })
end, { desc = "Convert .ipynb to .py with # %%", silent = true })

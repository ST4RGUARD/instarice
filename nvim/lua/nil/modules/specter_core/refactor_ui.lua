local M = {}

function M.show_blast_radius(impact_map, on_confirm)
  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.5)
  
  local lines = {
    " ⚠️  SPECTER REFACTOR PREVIEW",
    " ============================",
    " The following files will be impacted by your changes:",
    "",
  }

  for file, symbols in pairs(impact_map) do
    table.insert(lines, " 📂 " .. vim.fn.fnamemodify(file, ":."))
    for _, sym in ipairs(symbols) do
      table.insert(lines, "    └─ 󰊕 " .. sym)
    end
    table.insert(lines, "")
  end

  table.insert(lines, " [y] Proceed with Multi-file Refactor")
  table.insert(lines, " [n] Edit primary file only")
  table.insert(lines, " [q] Cancel operation")

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, "modifiable", false)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = "minimal",
    border = "rounded",
    title = " Impact Analysis ",
    title_pos = "center",
  })

  -- Keybindings for the floating window
  local function close() vim.api.nvim_win_close(win, true) end

  vim.keymap.set("n", "y", function() close(); on_confirm(true) end, { buffer = buf })
  vim.keymap.set("n", "n", function() close(); on_confirm(false) end, { buffer = buf })
  vim.keymap.set("n", "q", function() close() end, { buffer = buf })
end

return M

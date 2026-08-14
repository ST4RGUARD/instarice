local M = {}

local patch_engine = require("nil.modules.specter_core.patch_engine")

local buf, win

-----------------------------------------------------
-- OPEN WINDOW
-----------------------------------------------------
local function open()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    return
  end

  buf = vim.api.nvim_create_buf(false, true)

  vim.bo[buf].filetype = "diff"
  vim.bo[buf].buftype = "nofile"

  vim.cmd("botright vsplit")
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
end

-----------------------------------------------------
-- SHOW PATCH
-----------------------------------------------------
function M.show(patch)
  open()

  local lines = {
    "--- PATCH PREVIEW ---",
    "Range: " .. patch.start_line .. " → " .. patch.end_line,
    "",
    "--- NEW CONTENT ---",
  }

  for _, l in ipairs(patch.new_lines or {}) do
    table.insert(lines, l)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.keymap.set("n", "y", function()
    patch_engine.apply(vim.api.nvim_get_current_buf(), patch)
    vim.cmd("bd " .. buf)
    print("[PATCH] applied")
  end, { buffer = buf })

  vim.keymap.set("n", "n", function()
    vim.cmd("bd " .. buf)
    print("[PATCH] rejected")
  end, { buffer = buf })
end

return M

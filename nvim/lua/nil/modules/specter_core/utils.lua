local M = {}

function M.decode_newlines(str)
  if type(str) ~= "string" then return str end
  str = str:gsub("\\\\n", "\n")
  str = str:gsub("\\n", "\n")
  return str
end

-----------------------------------------------------
-- GET ACTIVE PROJECT DIR
-- Priority order:
--   1. Oil buffer path (if Oil is the focused window)
--      Oil stores its current dir in the buffer name: oil:///path/to/dir
--   2. First real code file open in any buffer
--   3. vim.fn.getcwd() fallback
--
-- This handles the Oil + Zoxide case where getcwd()
-- still points to the original launch dir even though
-- Oil has navigated you somewhere else entirely.
-----------------------------------------------------
function M.get_active_project_dir()
  -- 1. Check if the current window is an Oil buffer
  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_name = vim.api.nvim_buf_get_name(cur_buf)

  if cur_name:match("^oil://") then
    -- Oil buffer name is oil:///absolute/path — strip the scheme
    local oil_dir = cur_name:gsub("^oil://", "")
    if oil_dir ~= "" and vim.fn.isdirectory(oil_dir) == 1 then
      return oil_dir
    end
  end

  -- 2. Check all windows — if any visible window shows an Oil buffer, use that
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local name = vim.api.nvim_buf_get_name(buf)
    if name:match("^oil://") then
      local oil_dir = name:gsub("^oil://", "")
      if oil_dir ~= "" and vim.fn.isdirectory(oil_dir) == 1 then
        return oil_dir
      end
    end
  end

  -- 3. First real code file in any loaded buffer
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local n = vim.api.nvim_buf_get_name(b)
    if n ~= "" and not n:match("^oil://") and vim.bo[b].buftype == "" then
      return vim.fn.fnamemodify(n, ":p:h")
    end
  end

  -- 4. Fallback
  return vim.fn.getcwd()
end

return M

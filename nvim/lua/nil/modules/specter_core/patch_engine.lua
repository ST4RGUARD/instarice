local M = {}

-----------------------------------------------------
-- APPLY STRUCTURED PATCH
-----------------------------------------------------
function M.apply(buf, patch)
  if not buf or not patch then
    return false, "invalid patch"
  end

  local ok, lines = pcall(vim.api.nvim_buf_get_lines,
    buf,
    patch.start_line,
    patch.end_line + 1,
    false
  )

  if not ok then
    return false, "failed to read buffer"
  end

  local new_lines = patch.new_lines

  if type(new_lines) == "string" then
    new_lines = vim.split(new_lines, "\n")
  end

  vim.api.nvim_buf_set_lines(
    buf,
    patch.start_line,
    patch.end_line + 1,
    false,
    new_lines
  )

  return true
end

return M

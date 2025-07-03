local M = {}

function M.get_buffer_dir()
  local bufname = vim.api.nvim_buf_get_name(0)
  local ft = vim.bo.filetype

  if ft == "oil" then
    return bufname:gsub("^oil://", "")
  elseif bufname ~= "" then
    return vim.fn.expand("%:p:h")
  else
    return vim.loop.cwd()
  end
end

return M

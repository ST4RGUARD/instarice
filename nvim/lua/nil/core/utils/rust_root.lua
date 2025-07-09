local M = {}

function M.rust_root()
  local buf_path = vim.api.nvim_buf_get_name(0)
  local start_dir = vim.fn.fnamemodify(buf_path, ":p:h")
  local cargo_toml = vim.fn.findfile("Cargo.toml", start_dir .. ";")
  if cargo_toml == "" then
    vim.notify("Cargo.toml not found", vim.log.levels.ERROR)
    return vim.fn.getcwd()
  end
  return vim.fn.fnamemodify(cargo_toml, ":p:h")
end

return M


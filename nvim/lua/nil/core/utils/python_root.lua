local M = {}

function M.get_project_python()
  local start_dir = vim.fn.expand("%:p:h")

  local root_path = vim.fs.find({ ".venv", "pyproject.toml", ".git" }, {
    upward = true,
    type = "directory",
    path = start_dir,
  })[1]

  if not root_path then
    vim.notify("[python_root] Could not find project root containing .venv", vim.log.levels.ERROR)
    return nil
  end

  if vim.endswith(root_path, ".venv") then
    root_path = vim.fn.fnamemodify(root_path, ":h")
  end

  local python_path = root_path .. "/.venv/bin/python"

  if vim.fn.filereadable(python_path) == 0 then
    vim.notify("[python_root] Python executable not found at: " .. python_path, vim.log.levels.ERROR)
    return nil
  end

  return python_path
end

return M



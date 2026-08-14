local M = {}

function M.find_functions() return {} end

function M.find_imports(lines)
  local imports = {}

  for _, l in ipairs(lines) do
    local mod = l:match('"([^"]+)"')
    if mod then table.insert(imports, mod) end
  end

  return imports
end

function M.find_calls() return {} end
function M.find_aliases() return {} end

return M

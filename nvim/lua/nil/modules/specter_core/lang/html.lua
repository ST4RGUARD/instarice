local M = {}

function M.find_functions() return {} end
function M.find_calls() return {} end
function M.find_aliases() return {} end

-----------------------------------------------------
-- LINKED RESOURCES
-----------------------------------------------------
function M.find_imports(lines)
  local imports = {}

  for _, l in ipairs(lines) do
    local src = l:match('src="([^"]+)"')
    if src then table.insert(imports, src) end

    local href = l:match('href="([^"]+)"')
    if href then table.insert(imports, href) end
  end

  return imports
end

return M

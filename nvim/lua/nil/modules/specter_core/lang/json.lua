local M = {}

-----------------------------------------------------
-- JSON HAS NO FUNCTIONS
-----------------------------------------------------
function M.find_functions() return {} end
function M.find_calls() return {} end
function M.find_aliases() return {} end

-----------------------------------------------------
-- EXTRACT KEYS (useful for configs)
-----------------------------------------------------
function M.find_imports(lines)
  local imports = {}

  for _, l in ipairs(lines) do
    local key = l:match('"([%w_%-%./]+)"%s*:')
    if key then table.insert(imports, key) end
  end

  return imports
end

return M

local M = {}

function M.find_functions() return {} end
function M.find_calls() return {} end
function M.find_aliases() return {} end

-----------------------------------------------------
-- SELECTORS (metadata only)
-----------------------------------------------------
function M.find_imports(lines)
  local selectors = {}

  for _, l in ipairs(lines) do
    local sel = l:match("^([%w%-%._#]+)%s*{")
    if sel then table.insert(selectors, sel) end
  end

  return selectors
end

return M

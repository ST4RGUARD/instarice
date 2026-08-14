local M = {}

function M.find_functions() return {} end

function M.find_imports(lines)
  local imports = {}

  for _, l in ipairs(lines) do
    local hdr = l:match('#include%s+[<"]([^">]+)[">]')
    if hdr then table.insert(imports, hdr) end
  end

  return imports
end

function M.find_calls() return {} end
function M.find_aliases() return {} end

return M

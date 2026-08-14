local M = {}

-----------------------------------------------------
-- FUNCTIONS (bash style)
-----------------------------------------------------
function M.find_functions(lines)
  local results = {}

  for _, l in ipairs(lines) do
    local fn = l:match("^(%w+)%s*%(%s*%)")
    if fn then table.insert(results, fn) end
  end

  return results
end

-----------------------------------------------------
-- IMPORTS (source)
-----------------------------------------------------
function M.find_imports(lines)
  local imports = {}

  for _, l in ipairs(lines) do
    local src = l:match("^source%s+(.+)")
    if src then table.insert(imports, src) end
  end

  return imports
end

-----------------------------------------------------
-- CALLS (command execution)
-----------------------------------------------------
function M.find_calls(lines)
  local calls = {}

  for _, l in ipairs(lines) do
    local cmd = l:match("^(%w+)")
    if cmd then
      table.insert(calls, { name = cmd })
    end
  end

  return calls
end

function M.find_aliases() return {} end

return M

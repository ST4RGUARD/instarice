local ts = vim.treesitter
local M = {}

-----------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------
function M.find_functions(root, bufnr)
  local results = {}

  local query = ts.query.parse("rust", [[
    (function_item name: (identifier) @name)
  ]])

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    table.insert(results, ts.get_node_text(node, bufnr))
  end

  return results
end

-----------------------------------------------------
-- IMPORTS
-----------------------------------------------------
function M.find_imports(lines)
  local imports = {}

  for _, l in ipairs(lines) do
    local use = l:match("^use%s+([%w_:]+)")
    if use then
      table.insert(imports, use)
    end

    local mod = l:match("^mod%s+([%w_]+)")
    if mod then
      table.insert(imports, mod)
    end
  end

  return imports
end

-----------------------------------------------------
-- CALLS
-----------------------------------------------------
function M.find_calls(root, bufnr)
  local calls = {}

  local query = ts.query.parse("rust", [[
    (call_expression
      function: (identifier) @fn)
  ]])

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    table.insert(calls, {
      name = ts.get_node_text(node, bufnr)
    })
  end

  return calls
end

-----------------------------------------------------
-- NO ALIASES (KEEP SIMPLE)
-----------------------------------------------------
function M.find_aliases()
  return {}
end

return M

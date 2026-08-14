local ts = vim.treesitter
local M = {}

-----------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------
function M.find_functions(root, bufnr)
  local results = {}

  local query = ts.query.parse("ruby", [[
    (method name: (identifier) @name)
    (singleton_method name: (identifier) @name)
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
    local req = l:match('require%s+[\'"]([^\'"]+)[\'"]')
    if req then
      table.insert(imports, req)
    end

    local rel = l:match('require_relative%s+[\'"]([^\'"]+)[\'"]')
    if rel then
      table.insert(imports, rel)
    end
  end

  return imports
end

-----------------------------------------------------
-- CALLS
-----------------------------------------------------
function M.find_calls(root, bufnr)
  local calls = {}

  local query = ts.query.parse("ruby", [[
    (call
      method: (identifier) @method)

    (call
      receiver: (identifier) @recv
      method: (identifier) @method)
  ]])

  for _, node in query:iter_captures(root, bufnr, 0, -1) do
    local text = ts.get_node_text(node, bufnr)

    table.insert(calls, {
      name = text
    })
  end

  return calls
end

-----------------------------------------------------
-- ALIASES (MINIMAL, NO GUESSING LOGIC)
-----------------------------------------------------
function M.find_aliases(lines)
  local aliases = {}

  for _, l in ipairs(lines) do
    local var, mod = l:match('(%w+)%s*=%s*(%u%w+)')
    if var and mod then
      aliases[var] = mod
    end
  end

  return aliases
end

return M

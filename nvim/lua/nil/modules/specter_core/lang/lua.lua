local ts = vim.treesitter
local M = {}

-----------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------
function M.find_functions(ctx)
  local results = {}
  local bufnr = ctx.bufnr

  if not ctx.root then return results end

  local query = ts.query.parse("lua", [[
    (function_definition name: (identifier) @name)
  ]])

  for _, node in query:iter_captures(ctx.root, bufnr, 0, -1) do
    table.insert(results, ts.get_node_text(node, bufnr))
  end

  return results
end

-----------------------------------------------------
-- IMPORTS
-----------------------------------------------------
function M.find_imports(ctx)
  local imports = {}

  for _, line in ipairs(ctx.lines) do
    local mod = line:match('require%s*%(%s*["\']([^"\']+)["\']%s*%)')
    if mod then table.insert(imports, mod) end
  end

  return imports
end

-----------------------------------------------------
-- CALLS
-----------------------------------------------------
function M.find_calls(ctx)
  local calls = {}
  local bufnr = ctx.bufnr

  if not ctx.root then return calls end

  local query = ts.query.parse("lua", [[
    (call function: (identifier) @fn)
    (method_call
      receiver: (identifier) @recv
      method: (identifier) @method)
  ]])

  for id, node in query:iter_captures(ctx.root, bufnr, 0, -1) do
    table.insert(calls, {
      name = ts.get_node_text(node, bufnr)
    })
  end

  return calls
end

-----------------------------------------------------
-- ALIASES
-----------------------------------------------------
function M.find_aliases(ctx)
  local aliases = {}

  for _, line in ipairs(ctx.lines) do
    local var, mod = line:match('local%s+(%w+)%s*=%s*require%s*%(%s*["\']([^"\']+)["\']%s*%)')
    if var and mod then
      aliases[var] = mod
    end
  end

  return aliases
end

return M

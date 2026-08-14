local ts = vim.treesitter
local M = {}

function M.find_functions(ctx)
  local results = {}
  local bufnr = ctx.bufnr

  if not ctx.root then return results end

  local query = ts.query.parse("python", [[
    (function_definition name: (identifier) @name)
  ]])

  for _, node in query:iter_captures(ctx.root, bufnr, 0, -1) do
    table.insert(results, ts.get_node_text(node, bufnr))
  end

  return results
end

function M.find_imports(ctx)
  local imports = {}

  for _, l in ipairs(ctx.lines) do
    local mod = l:match("^import%s+([%w_%.]+)")
    if mod then table.insert(imports, mod) end

    local from = l:match("^from%s+([%w_%.]+)%s+import")
    if from then table.insert(imports, from) end
  end

  return imports
end

function M.find_calls() return {} end
function M.find_aliases() return {} end

return M

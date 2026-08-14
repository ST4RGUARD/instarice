local ts = vim.treesitter
local M = {}

-----------------------------------------------------
-- FUNCTIONS
-----------------------------------------------------
function M.find_functions(ctx)
  local results = {}
  local bufnr = ctx.bufnr

  if not ctx.root then return results end

  local query = ts.query.parse("javascript", [[
    (function_declaration name: (identifier) @name)
    (method_definition name: (property_identifier) @name)
    (lexical_declaration
      (variable_declarator
        name: (identifier) @name
        value: (arrow_function)))
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

  for _, l in ipairs(ctx.lines) do
    local esm = l:match('from%s+[\'"]([^\'"]+)[\'"]')
    if esm then table.insert(imports, esm) end

    local req = l:match('require%([\'"]([^\'"]+)[\'"]%)')
    if req then table.insert(imports, req) end
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

  local query = ts.query.parse("javascript", [[
    (call_expression
      function: (identifier) @fn)

    (call_expression
      function: (member_expression
        object: (identifier) @obj
        property: (property_identifier) @method))
  ]])

  local captures = query.captures

  for id, node in query:iter_captures(ctx.root, bufnr, 0, -1) do
    local cap = captures[id]

    if cap == "fn" then
      table.insert(calls, {
        name = ts.get_node_text(node, bufnr)
      })

    elseif cap == "method" then
      table.insert(calls, {
        name = ts.get_node_text(node, bufnr)
      })
    end
  end

  return calls
end

-----------------------------------------------------
-- ALIASES
-----------------------------------------------------
function M.find_aliases(ctx)
  local aliases = {}

  for _, l in ipairs(ctx.lines) do
    local var, mod = l:match('const%s+(%w+)%s*=%s*require%([\'"]([^\'"]+)[\'"]%)')
    if var and mod then
      aliases[var] = mod
    end

    local var2, mod2 = l:match('import%s+(%w+)%s+from%s+[\'"]([^\'"]+)[\'"]')
    if var2 and mod2 then
      aliases[var2] = mod2
    end
  end

  return aliases
end

return M

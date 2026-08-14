local ts = vim.treesitter
local adapters = require("nil.modules.specter_core.lang_adapter")

local M = {}

-----------------------------------------------------
-- PARSE TREE
-----------------------------------------------------
function M.parse(bufnr, lang)
  bufnr = bufnr or 0
  lang = lang or vim.bo.filetype

  local parser = ts.get_parser(bufnr, lang)
  local tree = parser:parse()[1]

  return tree:root()
end

-----------------------------------------------------
-- GET FUNCTIONS (ADAPTER-FIRST)
-----------------------------------------------------
function M.get_functions(bufnr, lang)
  bufnr = bufnr or 0
  lang = lang or vim.bo.filetype

  local root = M.parse(bufnr, lang)

  local adapter = adapters.get(lang)

  ---------------------------------------------------
  -- USE LANGUAGE ADAPTER IF AVAILABLE
  ---------------------------------------------------
  if adapter and adapter.find_functions then
    return adapter.find_functions(root, bufnr) or {}
  end

  ---------------------------------------------------
  -- FALLBACK (GENERIC WALK)
  ---------------------------------------------------
  local results = {}

  local function walk(node)
    local type = node:type()

    if type:match("function") then
      local sr, _, er, _ = node:range()

      local lines = vim.api.nvim_buf_get_lines(bufnr, sr, er + 1, false)

      table.insert(results, {
        type = type,
        range = {
          start_row = sr,
          end_row = er,
        },
        code = table.concat(lines, "\n"),
        node = node,
      })
    end

    for child in node:iter_children() do
      walk(child)
    end
  end

  walk(root)

  return results
end

-----------------------------------------------------
-- EXTRACT FUNCTION BY NAME (SAFER)
-----------------------------------------------------
function M.extract_function(bufnr, lang, name)
  local funcs = M.get_functions(bufnr, lang)

  for _, f in ipairs(funcs) do
    if f.name == name or (f.code and f.code:match("function%s+" .. name)) then
      return f
    end
  end

  return nil
end

return M

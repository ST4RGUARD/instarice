local M = {}

local adapters = {}

-----------------------------------------------------
-- REGISTER LANGUAGE ADAPTER
-----------------------------------------------------
function M.register(lang, adapter)
  adapters[lang] = adapter
end

-----------------------------------------------------
-- GET ADAPTER
-----------------------------------------------------
function M.get(lang)
  return adapters[lang]
end

-----------------------------------------------------
-- BUILD CONTEXT (NORMALIZED INPUT)
-----------------------------------------------------
local function build_ctx(lang, bufnr, root, lines)
  return {
    lang = lang,
    bufnr = bufnr,
    root = root,
    lines = lines or vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
  }
end

-----------------------------------------------------
-- EXTRACT SEMANTIC SNAPSHOT (FIXED CONTRACT)
-----------------------------------------------------
function M.extract(lang, bufnr, root, lines)
  local adapter = adapters[lang]

  if not adapter then
    return {
      functions = {},
      imports = {},
      calls = {},
      aliases = {},
    }
  end

  local ctx = build_ctx(lang, bufnr, root, lines)

  return {
    functions = adapter.find_functions(ctx) or {},
    imports = adapter.find_imports(ctx) or {},
    calls = adapter.find_calls(ctx) or {},
    aliases = adapter.find_aliases(ctx) or {},
  }
end

return M

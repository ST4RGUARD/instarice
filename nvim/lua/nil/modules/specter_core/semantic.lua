local lsp = require("nil.modules.specter_core.lsp")
local M = {}

--- Parses natural language to pull out a filename and a directory hint.
function M.extract_intent(query)
  if not query then return nil, nil end
  local q = query:lower():gsub("❯", "")
  
  -- Captures filenames (e.g., http.rb, main.rs)
  local file = q:match("([%w%-_%.]+%.%a+)")
  
  -- Patterns for directory hints, prioritizing absolute paths and project names
  local dir_patterns = {
    "inside%s+the%s+([/%w%-_%.]+)",
    "inside%s+([/%w%-_%.]+)",
    "in%s+the%s+([/%w%-_%.]+)",
    "in%s+([/%w%-_%.]+)",
    "directory%s+([/%w%-_%.]+)"
  }

  local dir = nil
  for _, p in ipairs(dir_patterns) do
    local match = q:match(p)
    if match then
      dir = match:gsub("%s+$", "") -- Clean trailing whitespace
      break
    end
  end
  
  return file, dir
end

--- Resolves a file query to a list of candidates, strictly anchored to a directory if provided.
function M.resolve(query, directory)
  if not query or query == "" then return { files = {}, symbols = {} } end
  
  -- Normalize the root path (default to CWD if no directory provided)
  local root = (directory and directory ~= "") and directory or vim.fn.getcwd()
  root = vim.fn.fnamemodify(root, ":p")
  
  -- Extract just the filename to use for anchored searching
  local file_hint = query:match("([^/]+%.%a+)$") or query

  -- 1. STRICT SEARCH: Matches the filename exactly from the start (^) to end ($) 
  -- of the filename string, scoped inside the root directory.
  local cmd = string.format("fd -t f -i '^%s$' '%s' 2>/dev/null", file_hint, root)
  local files = vim.fn.systemlist(cmd)

  -- 2. FUZZY FALLBACK: If strict fails, do a looser search but stay within the root.
  if #files == 0 then
    cmd = string.format("fd -t f -i '%s' '%s' 2>/dev/null", file_hint, root)
    files = vim.fn.systemlist(cmd)
  end

  -- 3. LSP SYMBOLS: Gather workspace symbols as a fallback/supplement
  local out_symbols = {}
  local lsp_hits = lsp.workspace_symbols(query) or {}
  for _, r in pairs(lsp_hits) do
    if r.result then
      for _, sym in ipairs(r.result) do
        table.insert(out_symbols, sym)
      end
    end
  end

  return { files = files, symbols = out_symbols }
end

return M

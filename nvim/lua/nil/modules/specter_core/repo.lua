local utils = require("nil.modules.specter_core.utils")
local M = {}

local function trace(msg)
  vim.schedule(function() vim.notify("[SPECTER-REPO] " .. msg) end)
end

-- Helper to find files relative to the project root
local function run_files(directory)
  local root = (directory and directory ~= "") and directory or utils.get_active_project_dir()
  return vim.fn.systemlist({ "rg", "--files", "--no-messages", root })
end

-- Resolve a filename or partial path into a full absolute path
local function resolve_file(path, directory)
  if not path or path == "" then return nil, "EMPTY_PATH" end
  
  if path:sub(1, 1) == "/" and vim.fn.filereadable(path) == 1 then
    return path
  end

  local root = (directory and directory ~= "") and directory or utils.get_active_project_dir()
  root = vim.fn.fnamemodify(root, ":p"):gsub("/$", "")
  
  local results = run_files(root)

  -- rg --files returns absolute paths when given an absolute root.
  -- Avoid doubling the root by checking if f is already absolute.
  local function to_abs(f)
    if f:sub(1, 1) == "/" then
      return vim.fn.simplify(f)
    end
    return vim.fn.simplify(vim.fn.fnamemodify(root .. "/" .. f:gsub("^./", ""), ":p"))
  end

  -- Pass 1: exact filename match
  for _, f in ipairs(results) do
    local abs_path = to_abs(f)
    local filename = abs_path:match("([^/]+)$")
    if filename == path or abs_path == path then return abs_path end
  end

  -- Pass 2: partial path match
  for _, f in ipairs(results) do
    local abs_path = to_abs(f)
    if abs_path:find(path, 1, true) then return abs_path end
  end

  return nil, "NO_MATCH"
end

function M.read(path, directory)
  if not path then return { ok = false, error = "EMPTY_PATH", result = "" } end
  local resolved, err = resolve_file(path, directory)
  if not resolved then return { ok = false, error = err, result = "" } end

  local ok, content = pcall(vim.fn.readfile, resolved)
  if not ok then return { ok = false, error = "READ_FAILED", result = "" } end

  return { ok = true, result = table.concat(content, "\n") }
end

function M.search(query, directory)
  if not query or query == "" then return { ok = true, results = {} } end
  
  -- 1. ENHANCED SYMBOL EXTRACTION
  -- Filters out agent chatter keywords to find the actual code symbol
  local clean_query = utils.decode_newlines(query)
  if clean_query:find(" ") then
    local skip_words = { 
      ["function"] = true, ["the"] = true, ["rename"] = true, ["fn"] = true,
      ["to"] = true, ["find"] = true, ["method"] = true, ["variable"] = true 
    }
    
    for word in clean_query:gmatch("[%w_]+") do
      local lower_word = word:lower()
      -- Pick word if it's not a keyword AND (has underscores OR is long enough)
      if not skip_words[lower_word] and (word:find("_") or #word > 3) then
        clean_query = word
        break
      end
    end
  end
  clean_query = clean_query:gsub("%(%)", "")

  -- 2. DYNAMIC PATH ALIGNMENT
  local active_dir = utils.get_active_project_dir()
  local cwd = vim.fn.getcwd()
  
  -- Use active dir if it's a sub-directory of the current workspace
  local root = directory or cwd
  if active_dir:find(cwd, 1, true) and #active_dir > #cwd then
    root = active_dir
    -- Physically align Neovim's CWD to the sub-project
    vim.api.nvim_set_current_dir(root)
  end
               
  root = vim.fn.fnamemodify(root, ":p"):gsub("/$", "")
  trace("Targeting: [" .. clean_query .. "] in " .. root)

  -- 3. Execute ripgrep
  local cmd = { "rg", "--vimgrep", "-F", "--smart-case", "--no-messages", clean_query, root }
  local raw = vim.fn.systemlist(cmd)
  
  if #raw == 0 then
    trace("No matches found. Retrying with --no-ignore...")
    local fallback = { "rg", "--vimgrep", "-F", "--smart-case", "--no-ignore", "--hidden", clean_query, root }
    raw = vim.fn.systemlist(fallback)
  end

  local results = {}
  for _, line in ipairs(raw) do
    local file, lnum, col, text = line:match("^([^:]+):(%d+):(%d+):(.*)")
    if file then
      local full_path = file:sub(1, 1) == "/" and file or (root .. "/" .. file)
      local abs_path = vim.fn.simplify(vim.fn.fnamemodify(full_path, ":p"))
      
      table.insert(results, {
        path = abs_path, 
        line = tonumber(lnum), 
        col = tonumber(col), 
        snippet = text
      })
    end
  end

  trace("Found " .. #results .. " matches.")
  return { ok = true, results = results }
end

return M

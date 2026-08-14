local ast = require("nil.modules.specter_core.ast")
local adapters = require("nil.modules.specter_core.lang_adapter")
local lsp_calls = require("nil.modules.specter_core.lsp_callgraph")

local M = {}

-- PERSISTENCE CONFIG
M.index_dir = vim.fn.expand("$HOME/.config/nvim/specter")
M.index_path = M.index_dir .. "/semantic_index.json"

M.graph = {
  root = nil,
  host = nil,
  symbols = {},
  calls = {},
  reverse_calls = {},
  files = {},
  timestamp = 0,
}

local function log(msg)
  vim.schedule(function()
    print("[GRAPH-DEBUG] " .. msg)
  end)
end

function M.debug_path_integrity()
  print("\n--- SPECTER PATH INTEGRITY CHECK ---")

  print("1. REGISTERED FILES (The 'Source of Truth'):")
  if vim.tbl_isempty(M.graph.files) then print("   !! No files registered.") end
  for path, _ in pairs(M.graph.files) do
    print(string.format("   Path: [%s]", path))
  end

  print("\n2. SYMBOL DEFINITIONS:")
  if vim.tbl_isempty(M.graph.symbols) then print("   !! No symbols found.") end
  for name, defs in pairs(M.graph.symbols) do
    for _, d in ipairs(defs) do
      print(string.format("   Symbol: [%s] | Location: [%s]", name, d.file))
    end
  end

  print("\n3. REVERSE CALLS (Linking check):")
  if vim.tbl_isempty(M.graph.reverse_calls) then print("   !! No links established.") end
  for name, callers in pairs(M.graph.reverse_calls) do
    for _, c in ipairs(callers) do
      print(string.format("   Symbol [%s] is called by [%s]", name, c.caller))
    end
  end
  print("--- END OF CHECK ---\n")
end

function M.debug_dump(symbol_name)
  print("--- GRAPH DUMP ---")
  if symbol_name then
    print("Definitions:", vim.inspect(M.graph.symbols[symbol_name] or "NONE"))
    print("Reverse Calls:", vim.inspect(M.graph.reverse_calls[symbol_name] or "NONE"))
  else
    print("Symbols Indexed:", vim.tbl_count(M.graph.symbols))
    print("Files in Graph:", vim.tbl_count(M.graph.files))
  end
end

local function ensure_dir()
  if vim.fn.isdirectory(M.index_dir) == 0 then
    vim.fn.mkdir(M.index_dir, "p")
  end
end

function M.save_to_disk()
  ensure_dir()
  M.graph.timestamp = os.time()
  M.graph.host = vim.loop.os_uname().nodename
  M.graph.root = vim.fn.getcwd()
  local f = io.open(M.index_path, "w")
  if f then
    f:write(vim.fn.json_encode(M.graph))
    f:close()
    return true
  end
  return false
end

function M.load_from_disk()
  local f = io.open(M.index_path, "r")
  if not f then return false end
  local content = f:read("*all")
  f:close()
  local ok, decoded = pcall(vim.fn.json_decode, content)
  if ok and decoded.root == vim.fn.getcwd() then
    M.graph = decoded
    return true
  end
  return false
end

local function extract_symbol_name(f, lang)
  local name = f.name
  if not name or name == "" or name:find("%s") or name:find("%(") then
    if lang == "rust" then
      name = f.code:match("fn%s+([%w_]+)")
    elseif lang == "go" then
      name = f.code:match("func%s+%(?.*%)?%s*([%w_]+)%s*%(")
    end
  end
  return name and name:gsub("[%s%(%<]", "") or "anonymous"
end

-----------------------------------------------------
-- PASS 1: INDEX DEFINITIONS
-----------------------------------------------------
function M.index_definitions(bufnr, lang, file)
  file = vim.fn.fnamemodify(file, ":p")
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local ok, funcs = pcall(ast.get_functions, bufnr, lang)
  if not ok or type(funcs) ~= "table" then return end

  for _, f in ipairs(funcs) do
    local name = extract_symbol_name(f, lang)
    if name and name ~= "anonymous" then
      M.graph.symbols[name] = M.graph.symbols[name] or {}
      table.insert(M.graph.symbols[name], { file = file, range = f.range, code = f.code })
    end
  end

  M.graph.files[file] = { content = table.concat(lines, "\n"), lang = lang }
end

-----------------------------------------------------
-- PASS 2: LINK CALLERS
-- FIX #2: lsp_callgraph was imported but never called.
-- We now run a LSP call hierarchy lookup for every
-- indexed symbol that has a known buffer position.
-- Static regex runs first as a fast baseline;
-- LSP results are merged in as higher-confidence links.
-----------------------------------------------------
function M.link_references()
  log("Starting Global Linking Pass (static + LSP)...")

  -- 2a. Static regex baseline (fast, no LSP needed)
  for file, data in pairs(M.graph.files) do
    for word in data.content:gmatch("([%w_]+)%s*%(") do
      if M.graph.symbols[word] then
        M.add_call(file, word, { file = file, type = "static" })
      end
    end
  end

  -- 2b. LSP call hierarchy (accurate, type-aware)
  -- Iterate known symbol definitions and ask LSP who calls them.
  for symbol_name, defs in pairs(M.graph.symbols) do
    for _, def in ipairs(defs) do
      local bufnr = vim.fn.bufnr(def.file)

      -- Only attempt if the buffer is loaded and an LSP client is attached
      if bufnr and bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
        local clients = vim.lsp.get_clients({ bufnr = bufnr })
        if clients and #clients > 0 then
          -- Use the start of the symbol's range as the position
          local range = def.range
          if range and range.start_row then
            local position = { line = range.start_row, character = 0 }

            -- incoming() = who calls this symbol
            local ok, incoming = pcall(lsp_calls.incoming, bufnr, position)
            if ok and incoming then
              for _, call_item in ipairs(incoming) do
                local caller_uri = call_item.from and call_item.from.uri
                if caller_uri then
                  local caller_file = vim.uri_to_fname(caller_uri)
                  M.add_call(caller_file, symbol_name, {
                    file = caller_file,
                    type = "lsp",
                    symbol = symbol_name,
                  })
                end
              end
            end
          end
        end
      end
    end
  end

  M.save_to_disk()
  log("Linking Complete (static + LSP).")
end

function M.add_call(caller, callee, meta)
  if not caller or not callee or caller == callee then return end
  M.graph.calls[caller] = M.graph.calls[caller] or {}
  table.insert(M.graph.calls[caller], { callee = callee, meta = meta })
  M.graph.reverse_calls[callee] = M.graph.reverse_calls[callee] or {}
  table.insert(M.graph.reverse_calls[callee], { caller = caller, meta = meta })
end

function M.get_impacted_files(name)
  local impacted = {}
  local callers = M.graph.reverse_calls[name] or {}

  log("Checking Impact for: " .. name .. " | Found " .. #callers .. " callers")
  for _, c in ipairs(callers) do
    local f = (type(c.caller) == "string" and (c.caller:find("/") or c.caller:find("\\"))) and c.caller or (c.meta and c.meta.file)
    if f then impacted[f] = true end
  end

  if M.graph.symbols[name] then
    for _, def in ipairs(M.graph.symbols[name]) do
      impacted[def.file] = true
    end
  end

  local res = {}
  for f in pairs(impacted) do table.insert(res, f) end
  return res
end

-- Expose index_file as an alias for index_definitions
-- (core_ingestor calls M.index_file — keep both names working)
function M.index_file(bufnr, lang, file)
  M.index_definitions(bufnr, lang, file)
end

function M.reindex_all(files_with_langs)
  M.graph.symbols = {}
  M.graph.calls = {}
  M.graph.reverse_calls = {}
  M.graph.files = {}

  -- Pass 1: definitions
  for _, item in ipairs(files_with_langs) do
    local bufnr = vim.fn.bufadd(item.file)
    vim.fn.bufload(bufnr)
    M.index_definitions(bufnr, item.lang, item.file)
  end

  -- Pass 2: link (static + LSP)
  M.link_references()
end

return M

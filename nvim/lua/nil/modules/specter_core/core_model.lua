local capabilities = require 'nil.modules.specter_core.capabilities'
local help = require 'nil.modules.specter_core.help'
local utils = require 'nil.modules.specter_core.utils'
local intent_parser = require 'nil.modules.specter_core.intent_parser'
local semantic = require 'nil.modules.specter_core.semantic'

local M = {}
M.state = { last_input = nil }

local function trace(msg)
  vim.schedule(function() vim.notify('[SPECTER-CORE] ' .. msg) end)
end

-----------------------------------------------------
-- GENERATION BRIDGES
-----------------------------------------------------

function M.generate_text_async(payload, callback)
  trace("Requesting Specter Teacher analysis (Async)...")
  capabilities.generate_async(payload, function(response)
    if response and response.ok then
      callback(response.text)
    else
      callback("⚠️ " .. (response.text or "Teaching Assistant failed to respond."))
    end
  end)
end

function M.generate_text(payload)
  trace("Requesting Teacher analysis (Sync)...")
  local response = capabilities.generate(payload)
  if response and response.ok then
    return response.text
  end
  return "⚠️ Error: Assistant failed."
end

-----------------------------------------------------
-- SEMANTIC RESOLUTION & PLANNING
-----------------------------------------------------

local function extract_workspace_hint(query)
  if not query then return nil end
  return query:match("inside%s+the%s+([/%w%-%_%.]+)")
      or query:match("inside%s+([/%w%-%_%.]+)")
      or query:match("in%s+the%s+([/%w%-%_%.]+)")
      or query:match("%s+in%s+([/%w%-%_%.]+)$")
      or query:match("directory%s+([/%w%-%_%.]+)")
end

local function semantic_explain(query, workspace_hint)
  trace('semantic.explain → ' .. tostring(query))
  local actual_dir = nil
  local hint_provided = false
  if workspace_hint then
    hint_provided = true
    workspace_hint = workspace_hint:gsub("/$", ""):gsub("%s+$", "")
    if workspace_hint:sub(1, 1) == "/" and vim.fn.isdirectory(workspace_hint) == 1 then
      actual_dir = workspace_hint
    else
      local dir_match = vim.fn.systemlist(string.format("fd -t d -i '^%s$' %s", workspace_hint, vim.fn.getcwd()))[1]
      if not dir_match then
        local cmd = string.format("fd -t d -i -uu --max-depth 12 '^%s$' $HOME", workspace_hint)
        dir_match = vim.fn.systemlist(cmd)[1]
      end
      if dir_match then actual_dir = dir_match end
    end
  end
  local resolved = { files = {}, symbols = {} }
  if hint_provided and not actual_dir then
    trace('Aborting search to prevent incorrect cross-project hits.')
  else
    resolved = semantic.resolve(query, actual_dir)
  end
  if #resolved.files == 0 and not hint_provided then
    resolved = semantic.resolve(query, "/")
  end
  local files = resolved.files or {}
  local symbols = resolved.symbols or {}
  local ranker = require 'nil.modules.specter_core.semantic_ranker'
  local ranked = ranker.rank(files, query, symbols)
  local best_file = ranked and ranked.best
  if not best_file then
    return { fallback = true, tool = 'repo.search', args = { query = query, directory = actual_dir } }
  end
  return { file = best_file, symbols = symbols, all_files = files, directory = actual_dir }
end

-----------------------------------------------------
-- FIND THE REAL PROJECT ROOT
-- Walks upward from a file path looking for project
-- markers. Returns the root dir or nil.
-----------------------------------------------------
local function find_project_root(from_path)
  if not from_path or from_path == "" then return nil end
  local markers = { 'Cargo.toml', 'go.mod', 'package.json', '.git', 'Makefile' }
  local match = vim.fs.find(markers, { path = from_path, upward = true })[1]
  if match then return vim.fs.dirname(match) end
  return nil
end

-----------------------------------------------------
-- GET BEST REAL FILE (skip specter UI buffers)
-- When the user types in the Specter input panel, the
-- "current buffer" is the prompt buffer which has no
-- real path. We walk all open buffers to find the most
-- recently used real code file.
-----------------------------------------------------
local function get_real_file_and_root()
  -- get_active_project_dir() already skips oil://, prompt bufs, specter UI etc.
  local active_dir = utils.get_active_project_dir()
  local root = find_project_root(active_dir) or active_dir

  -- Walk buffers to find the actual open file (same logic as utils but returns
  -- the full filename, not just the directory).
  local current_file = ""
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local n = vim.api.nvim_buf_get_name(b)
    if n ~= "" and not n:match("^oil://") and not n:match("specter")
       and vim.bo[b].buftype == "" and vim.fn.filereadable(n) == 1 then
      current_file = n
      break
    end
  end

  return current_file, root
end


function M.process(input)
  local raw_lower = input:lower()
  local steps = {}

  -- 1. STAGE: IMMEDIATE ACTION (Commit/Cancel)
  if raw_lower:match("^apply") or raw_lower:match("^commit") or raw_lower:match("looks good") then
    table.insert(steps, { tool = 'apply_patch', args = {} })
    return { goal = "commit changes", intent = "apply", steps = steps }
  elseif raw_lower:match("^cancel") or raw_lower:match("^undo") or raw_lower:match("^clear") then
    table.insert(steps, { tool = 'workspace.clear', args = {} })
    return { goal = "cancel changes", intent = "clear", steps = steps }
  end

  -- 2. STAGE: STANDARD INTENT PROCESSING
  local intent = intent_parser.parse(input)
  if not intent then return nil end
  M.state.last_input = input

  local action = intent.action
  local workspace_hint = extract_workspace_hint(input)

  -- 3. HELP / DISCOVERY
  if action == 'help' then
    table.insert(steps, { tool = 'specter.help', args = {} })
    return { goal = "help", intent = "help", steps = steps }
  end

  -- 4. RENAME SYMBOL (checked before generic replace)
  -- Patterns: "rename X to Y", "rename function X to Y", "rename method X to Y"
  -- Try specific patterns first (with noise words), then fall back to bare "rename X to Y"
  -- Lua has no non-capturing groups so we strip noise words before matching.
  local rename_input = input:gsub("[Rr]ename%s+the%s+", "rename ")
                            :gsub("[Rr]ename%s+function%s+", "rename ")
                            :gsub("[Rr]ename%s+method%s+", "rename ")
                            :gsub("[Rr]ename%s+fn%s+", "rename ")
  local old_sym, new_sym = rename_input:match("[Rr]ename%s+([%w_]+)%s+to%s+([%w_]+)")

  if old_sym and new_sym then
    local _, project_root = get_real_file_and_root()
    trace(string.format("Rename intent: '%s' → '%s' in %s", old_sym, new_sym, project_root))
    table.insert(steps, {
      tool = 'edit.rename_symbol',
      args = {
        old_name = old_sym,
        new_name = new_sym,
        project_root = project_root,
      }
    })
    return { goal = input, intent = "rename", steps = steps }
  end

  -- 5. GENERATE / IMPLEMENT
  -- "examine http2.rb help me write http3.rb"
  -- "implement a similar class for http3 based on http2.rb"
  if action == 'generate' then
    local _, project_root = get_real_file_and_root()

    -- Extract source file (what to learn from)
    local source_file = input:match("([%w%-_%.]+%.[%a]+)")

    -- Extract target file if mentioned
    local files = {}
    for f in input:gmatch("([%w%-_%.]+%.[%a]+)") do
      table.insert(files, f)
    end
    local target_file = #files > 1 and files[2] or nil

    -- Infer target from context if not explicit
    -- e.g. "http2.rb" → "http3.rb", "client_v1.go" → "client_v2.go"
    if not target_file and source_file then
      target_file = source_file
        :gsub("2", "3")
        :gsub("v1", "v2")
        :gsub("_old", "_new")
    end

    -- Build the 3-step plan: read → analyze → generate → stage
    if source_file then
      table.insert(steps, {
        tool = 'repo.read',
        args = { path = source_file, directory = project_root }
      })
      table.insert(steps, {
        tool = 'llm.analyze',
        args = {
          instruction = input,
          source_file = source_file,
          target_file = target_file,
        }
      })
      if target_file then
        table.insert(steps, {
          tool = 'repo.write',
          args = {
            path = target_file,
            directory = project_root,
            reason = "Generated from: " .. input,
          }
        })
      end
      return { goal = input, intent = "generate", steps = steps }
    end
  end

  -- 6. EXPLAIN
  -- "explain api.lua", "what does core_model do", "summarize tools.lua"
  if action == 'explain' or action == 'summarize' then
    local filename = intent.target and intent.target.file
    local _, project_root = get_real_file_and_root()
    if filename then
      -- Read the file first, then summarize it
      table.insert(steps, { tool = 'repo.read',     args = { path = filename, directory = project_root } })
      table.insert(steps, { tool = 'llm.summarize', args = { path = filename } })
    else
      -- No filename — summarize whatever was last read
      table.insert(steps, { tool = 'llm.summarize', args = {} })
    end
    return { goal = input, intent = action, steps = steps }
  end

  -- 6. READ FILE
  -- "read api.lua", "open core_model.lua", "show me config.lua"
  if action == 'read' then
    local filename = intent.target and intent.target.file
    if filename then
      local _, project_root = get_real_file_and_root()
      table.insert(steps, {
        tool = 'repo.read',
        args = { path = filename, directory = project_root }
      })
      return { goal = input, intent = "read", steps = steps }
    end
  end

  -- 6. FIND AND REPLACE
  if action == 'edit' or raw_lower:find("replace") then
    local find_term, replace_term = input:match("[Rr]eplace%s+the%s+word%s+([%w%-_%.]+)%s+with%s+([%w%-_%.]+)")
    if not find_term then
      find_term, replace_term = input:match("[Rr]eplace%s+([%w%-_%.]+)%s+with%s+([%w%-_%.]+)")
    end

    if find_term and replace_term then
      local scope = "current"
      if raw_lower:find("recursively") or raw_lower:find("project") or raw_lower:find("all files") then
        scope = "recursive"
      end

      local current_file, project_root = get_real_file_and_root()
      trace(string.format("Replace scope=%s | file=%s | root=%s", scope, current_file, project_root))

      table.insert(steps, {
        tool = 'edit.find_and_replace',
        args = {
          find = find_term,
          replace = replace_term,
          scope = scope,
          file = current_file,
          target = scope == "recursive" and project_root or vim.fn.fnamemodify(current_file, ":p:h"),
        }
      })
    else
      -- Strip action verbs before searching so "find usages of foo" searches "foo" not "usages"
      local clean_query = intent_parser.extract_query(input)
      table.insert(steps, { tool = 'repo.search', args = { query = clean_query } })
    end
  else
    -- Strip action verbs before searching so "find foo" searches "foo" not "find foo"
    local clean_query = intent_parser.extract_query(input)
    table.insert(steps, { tool = 'repo.search', args = { query = clean_query } })
  end

  return { goal = intent.raw, intent = action, steps = steps }
end

return M

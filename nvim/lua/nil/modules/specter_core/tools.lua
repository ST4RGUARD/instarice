local repo = require("nil.modules.specter_core.repo")
local workspace = require("nil.modules.specter_core.workspace")
local ast = require("nil.modules.specter_core.ast")
local lsp = require("nil.modules.specter_core.lsp")
local help = require("nil.modules.specter_core.help")

local M = {}

local function trace(msg)
  vim.schedule(function()
    vim.notify("[SPECTER-TOOLS] " .. msg)
  end)
end

local function clean(content)
  if type(content) ~= "string" then return "" end
  content = content:gsub("\\\\n", "\n"):gsub("\\n", "\n")
  content = content:gsub("\r\n", "\n"):gsub("\r", "\n")
  local buffer = ""
  for i = 1, #content do
    local b = content:byte(i)
    if (b >= 32 and b <= 126) or b == 10 or b == 13 then
      buffer = buffer .. string.char(b)
    end
  end
  content = buffer
  local p_s = "```"
  local p_e = "[%w]*" .. "\n"
  content = content:gsub(p_s .. p_e, ""):gsub(p_s, "")
  if content:match('^".*"$') or content:match("^'.*'$") then
    content = content:sub(2, -2)
  end
  content = content:gsub('\\"', '"')
  return content
end

local TEACHER_PROMPT = table.concat({
  "You are the Specter Coding Assistant, a mentor for students.",
  "Evaluate the code and report back with these two layers:",
  "",
  "1. Technical Architecture:",
  "    - Identify language and features (e.g., Rust Vectors).",
  "    - Explain syntax, patterns, and logic flow.",
  "    - Note dependencies or idioms.",
  "",
  "2. Human Understanding:",
  "    - Explain the code as a high-level story.",
  "    - Use analogies to describe the purpose."
}, "\n")

-----------------------------------------------------
-- SYMBOL RENAME: REFERENCE COLLECTION
-- Two passes:
--   1. rg --word-regexp  (fast, catches definitions,
--      calls, imports across all file types)
--   2. LSP textDocument/references (type-aware, catches
--      qualified calls like obj.method() that rg also
--      finds but LSP confirms with type info)
-- Results are deduped by absolute path.
-----------------------------------------------------
local function collect_references(old_name, project_root)
  local seen = {}
  local file_list = {}

  -- Pass 1: ripgrep word-boundary search
  local rg_hits = vim.fn.systemlist({
    "rg", "--files-with-matches", "--fixed-strings", "-w",
    "--no-messages", old_name, project_root
  })

  for _, path in ipairs(rg_hits) do
    local abs = vim.fn.simplify(vim.fn.fnamemodify(path, ":p"))
    if not seen[abs] then
      seen[abs] = true
      table.insert(file_list, abs)
    end
  end

  trace(string.format("rg: %d files contain '%s'", #file_list, old_name))

  -- Pass 2: LSP references from the active real buffer
  local active_buf = nil
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    local n = vim.api.nvim_buf_get_name(b)
    if n ~= "" and not n:match("^oil://") and not n:match("specter") and vim.bo[b].buftype == "" then
      active_buf = b
      break
    end
  end

  if active_buf then
    local clients = vim.lsp.get_clients({ bufnr = active_buf })
    if clients and #clients > 0 then
      local lsp_refs = lsp.references(active_buf) or {}
      for _, client_result in pairs(lsp_refs) do
        if client_result.result then
          for _, ref in ipairs(client_result.result) do
            local ref_path = vim.uri_to_fname(ref.uri)
            local abs = vim.fn.simplify(vim.fn.fnamemodify(ref_path, ":p"))
            if not seen[abs] then
              seen[abs] = true
              table.insert(file_list, abs)
              trace("LSP added extra file: " .. vim.fn.fnamemodify(abs, ":~:."))
            end
          end
        end
      end
    end
  end

  return file_list
end

-----------------------------------------------------
-- SYMBOL RENAME: PATCH STAGING
-- For each file, reads line by line and stages a patch
-- for every line that contains old_name at a word boundary.
-- Word boundary = not preceded/followed by [%w_].
-- Returns total patch count and a human-readable summary.
-----------------------------------------------------
local function stage_renames(file_list, old_name, new_name)
  local total = 0
  local patched_files = {}
  local escaped = old_name:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")

  for _, file_path in ipairs(file_list) do
    if vim.fn.filereadable(file_path) == 1 then
      local lines = vim.fn.readfile(file_path)
      local file_count = 0

      for i, line in ipairs(lines) do
        if line:find(escaped) then
          -- Word boundary check
          local s, e = line:find(escaped)
          local before = s > 1 and line:sub(s - 1, s - 1) or " "
          local after  = e < #line and line:sub(e + 1, e + 1) or " "

          if not before:match("[%w_]") and not after:match("[%w_]") then
            -- Replace all occurrences on this line
            local new_line = line:gsub(escaped, new_name)
            workspace.add(file_path, {
              start_line = i - 1,
              end_line   = i - 1,
              new_lines  = { new_line },
              reason     = string.format("rename '%s' → '%s'", old_name, new_name),
            })
            file_count = file_count + 1
            total = total + 1
          end
        end
      end

      if file_count > 0 then
        table.insert(patched_files,
          string.format("  %s (%d line%s)",
            vim.fn.fnamemodify(file_path, ":~:."),
            file_count,
            file_count == 1 and "" or "s"))
      end
    end
  end

  return total, patched_files
end

function M.execute(action, context)
  if not action or not action.tool then
    return { tool = "unknown", ok = false, error = "invalid action" }
  end

  trace("EXEC → " .. action.tool)

  -----------------------------------------------------
  -- REPO: SEARCH
  -----------------------------------------------------
  if action.tool == "repo.search" then
    local query = action.args and action.args.query or ""
    local dir = action.args and action.args.directory or context.cwd or vim.fn.getcwd()
    local res = repo.search(query, dir)
    return { tool = "repo.search", ok = res.ok, result = res.results or {} }
  end

  -----------------------------------------------------
  -- REPO: READ FILE
  -----------------------------------------------------
  if action.tool == "repo.read" then
    local path = action.args and action.args.path
    -- Use args.directory if provided (set by core_model read routing),
    -- fall back to context.cwd so both call sites work
    local directory = (action.args and action.args.directory) or context.cwd
    local res = repo.read(path, directory)
    local text = ""
    if type(res) == "table" then
      text = res.result or res.content or ""
    else
      text = tostring(res)
    end
    if path and res.ok then
      local b = vim.fn.bufadd(path)
      vim.fn.bufload(b)
      context.bufnr = b
      context.file = path
      context.lang = vim.filetype.match({ filename = path }) or "text"
    end
    context.last_content = text
    return { tool = action.tool, ok = res.ok, result = text, error = res.error }
  end

  -----------------------------------------------------
  -- BUFFER: LIST ACTIVE
  -----------------------------------------------------
  if action.tool == "buffer.list_active" then
    local active_files = {}
    local bufs = vim.api.nvim_list_bufs()
    for _, b in ipairs(bufs) do
      if vim.api.nvim_buf_is_loaded(b) then
        local name = vim.api.nvim_buf_get_name(b)
        local ft = vim.bo[b].filetype
        if name ~= "" and ft ~= "specter_log" and ft ~= "specter_input" then
          table.insert(active_files, { path = name, filetype = ft })
        end
      end
    end
    return { tool = "buffer.list_active", ok = true, result = active_files }
  end

  -----------------------------------------------------
  -- EDIT: FIND AND REPLACE
  -----------------------------------------------------
  if action.tool == "edit.find_and_replace" then
    local args = action.args or {}
    local find_str = args.find
    local replace_str = args.replace
    local scope = args.scope or "current"
    local search_root = args.target or context.cwd or vim.fn.getcwd()

    if not find_str or not replace_str then
      return { tool = "edit.find_and_replace", ok = false, error = "Missing find/replace strings" }
    end

    local tasks = {}

    if scope == "current" then
      local target_file = args.file or context.file or vim.api.nvim_buf_get_name(0)
      if target_file ~= "" and not target_file:match("^oil://") then
        table.insert(tasks, target_file)
      else
        return { tool = "edit.find_and_replace", ok = false, error = "No active file detected" }
      end
    elseif scope == "recursive" then
      search_root = vim.fn.fnamemodify(search_root, ":p"):gsub("/$", "")
      local raw = vim.fn.systemlist({
        "rg", "--files-with-matches", "--fixed-strings", "--case-sensitive",
        "--no-messages", find_str, search_root
      })
      for _, p in ipairs(raw) do
        local abs = p:sub(1,1) == "/" and p or (search_root .. "/" .. p)
        table.insert(tasks, vim.fn.simplify(abs))
      end
      trace(string.format("Recursive search for '%s' in %s → %d files", find_str, search_root, #tasks))
    end

    local count = 0
    local escaped_find = find_str:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")

    for _, file_path in ipairs(tasks) do
      if vim.fn.filereadable(file_path) == 1 then
        local lines = vim.fn.readfile(file_path)
        for i, line in ipairs(lines) do
          local s, e = line:find(escaped_find)
          if s then
            -- Word boundary: "nil" must not match inside "nilclass"
            local before = s > 1     and line:sub(s - 1, s - 1) or " "
            local after  = e < #line and line:sub(e + 1, e + 1) or " "
            if not before:match("[%w_]") and not after:match("[%w_]") then
              local new_line = line:gsub(escaped_find, replace_str)
              workspace.add(file_path, {
                start_line = i - 1,
                end_line   = i - 1,
                new_lines  = { new_line },
                reason     = "replace '" .. find_str .. "' -> '" .. replace_str .. "'",
              })
              count = count + 1
            end
          end
        end
      end
    end

    return {
      tool = "edit.find_and_replace",
      ok = true,
      result = string.format("Staged %d exact replacements in %s", count,
        scope == "current" and "the current file" or search_root)
    }
  end

  -----------------------------------------------------
  -- EDIT: RENAME SYMBOL
  -- Cross-file symbol rename for any language.
  -- Detects all references via rg (word-boundary) + LSP,
  -- stages line patches for every hit, shows diff for review.
  --
  -- Supported by design for: Rust, Go, Python, Ruby,
  -- JavaScript, TypeScript, C, C++, Lua and any language
  -- rg can search (i.e. all of them).
  -----------------------------------------------------
  if action.tool == "edit.rename_symbol" then
    local args = action.args or {}
    local old_name = args.old_name
    local new_name = args.new_name
    local project_root = args.project_root or context.cwd or vim.fn.getcwd()

    if not old_name or old_name == "" then
      return { tool = "edit.rename_symbol", ok = false, error = "Missing old_name" }
    end
    if not new_name or new_name == "" then
      return { tool = "edit.rename_symbol", ok = false, error = "Missing new_name" }
    end

    project_root = vim.fn.fnamemodify(project_root, ":p"):gsub("/$", "")
    trace(string.format("Renaming '%s' → '%s' in %s", old_name, new_name, project_root))

    local file_list = collect_references(old_name, project_root)

    if #file_list == 0 then
      return {
        tool = "edit.rename_symbol",
        ok = false,
        error = string.format("No references to '%s' found in %s", old_name, project_root)
      }
    end

    local total, patched_files = stage_renames(file_list, old_name, new_name)

    if total == 0 then
      return {
        tool = "edit.rename_symbol",
        ok = false,
        error = string.format("Found files but no word-boundary matches for '%s' — check spelling", old_name)
      }
    end

    local summary = string.format(
      "Staged %d rename patch%s across %d file%s:\n%s",
      total, total == 1 and "" or "es",
      #patched_files, #patched_files == 1 and "" or "s",
      table.concat(patched_files, "\n")
    )

    return { tool = "edit.rename_symbol", ok = true, result = summary }
  end

  -----------------------------------------------------
  -- LLM: SUMMARIZE
  -----------------------------------------------------
  if action.tool == "llm.summarize" then
    local content = action.args and action.args.content or context.last_content or ""
    content = clean(content)
    if content == "" then
      return { tool = "llm.summarize", ok = false, error = "Empty content" }
    end
    return {
      tool = "llm.summarize",
      ok = true,
      result = "PROMPT_MODE",
      payload = {
        contents = {{ parts = {{ text = "Summarize this code per instructions:\n\n" .. content }} }},
        systemInstruction = { parts = {{ text = TEACHER_PROMPT }} }
      }
    }
  end

  -----------------------------------------------------
  -- WORKSPACE: APPLY (COMMIT)
  -----------------------------------------------------
  if action.tool == "apply_patch" then
    local ok = workspace.apply_all()
    if ok then
      vim.schedule(function()
        vim.cmd("pclose")
        vim.notify("✅ Changes applied to disk.")
      end)
    end
    return { tool = action.tool, ok = ok, result = ok and "applied" or "failed" }
  end

  -----------------------------------------------------
  -- WORKSPACE: CLEAR (CANCEL)
  -----------------------------------------------------
  if action.tool == "workspace.clear" then
    workspace.clear()
    vim.schedule(function()
      vim.cmd("pclose")
      vim.notify("🚫 Changes cancelled and cleared.")
    end)
    return { tool = action.tool, ok = true, result = "cleared" }
  end

  -----------------------------------------------------
  -- LLM: ANALYZE
  -- Targeted analysis pass — different from llm.summarize
  -- (teacher mode). This is a developer-focused prompt that
  -- understands the code structurally and generates output
  -- for the next step in the chain (e.g. a new implementation).
  -- Reads context.last_content set by the preceding repo.read.
  -----------------------------------------------------
  if action.tool == "llm.analyze" then
    local args       = action.args or {}
    local source     = args.source_file or "the source file"
    local target     = args.target_file or "a new implementation"
    local instruction = args.instruction or ""
    local content_to_analyze = context.last_content or ""

    if content_to_analyze == "" then
      return { tool = "llm.analyze", ok = false, error = "No file content in context — run repo.read first" }
    end

    local prompt = string.format([[
You are an expert software engineer.

The developer has asked: %s

Below is the source file (%s) they want you to learn from.
Analyze it carefully, then generate a complete starter implementation of %s
following the same patterns, structure, and conventions.

Rules:
- Mirror the class/module structure of the source
- Keep method signatures idiomatic for the language
- Add TODO comments where HTTP/3 (or the target protocol/version) differs fundamentally
- Output ONLY the code for the new file — no explanations, no markdown fences
- Make it immediately useful as a starting point the developer can extend

SOURCE FILE (%s):
%s
]], instruction, source, target, source, content_to_analyze)

    return {
      tool = "llm.analyze",
      ok = true,
      result = "PROMPT_MODE",
      payload = {
        max_tokens = 8192,  -- code generation needs room
        contents = {{ parts = {{ text = prompt }} }},
        systemInstruction = { parts = {{ text = "You are a senior software engineer. Output only valid source code." }} }
      }
    }
  end

  -----------------------------------------------------
  -- REPO: WRITE (new file)
  -- Stages the LLM-generated content (context.last_content
  -- from llm.analyze) as a new file patch.
  -- The file doesn't exist yet — workspace treats line 0
  -- with empty original as an insert-only patch.
  -----------------------------------------------------
  if action.tool == "repo.write" then
    local args = action.args or {}
    local filename = args.path
    local directory = args.directory or context.cwd or vim.fn.getcwd()
    local reason = args.reason or "generated file"
    local generated = context.last_content or ""

    if not filename or filename == "" then
      return { tool = "repo.write", ok = false, error = "Missing target filename" }
    end
    if generated == "" then
      return { tool = "repo.write", ok = false, error = "No generated content in context — run llm.analyze first" }
    end

    -- Build the full target path
    local target_path
    if filename:sub(1, 1) == "/" then
      target_path = filename
    else
      -- Try to find the source file's directory to place the new file alongside it
      local source_dir = context.file and vim.fn.fnamemodify(context.file, ":p:h") or directory
      target_path = source_dir .. "/" .. filename
    end

    target_path = vim.fn.simplify(target_path)

    -- Stage as a patch — line 0 to 0, all new_lines are additions
    local new_lines = vim.split(generated, "\n")
    workspace.add(target_path, {
      start_line = 0,
      end_line   = 0,
      new_lines  = new_lines,
      reason     = reason,
    })

    local summary = string.format(
      "Staged new file: %s (%d lines) Review the diff and hit [Enter] to write it to disk.",
      vim.fn.fnamemodify(target_path, ":~:."),
      #new_lines
    )

    return { tool = "repo.write", ok = true, result = summary }
  end

  -----------------------------------------------------
  -- SPECTER: HELP
  -- Shows all available commands and examples.
  -----------------------------------------------------
  if action.tool == "specter.help" then
    return { tool = "specter.help", ok = true, result = help.render() }
  end

  return { tool = action.tool, ok = false, error = "unknown tool" }
end

return M

local semantic = require("nil.modules.specter_core.semantic")
local graph = require("nil.modules.specter_core.semantic_graph")
local repo = require("nil.modules.specter_core.repo")
local ast = require("nil.modules.specter_core.ast")
local ranker = require("nil.modules.specter_core.semantic_ranker")

local M = {}

-----------------------------------------------------
-- SAFE READ
-----------------------------------------------------
local function safe_read(file)
  local res = repo.read(file)
  if not res or not res.ok then
    return ""
  end
  return res.result or ""
end

-----------------------------------------------------
-- LOAD AST FUNCTIONS
-----------------------------------------------------
local function extract_functions(file)
  local bufnr = vim.fn.bufadd(file)
  vim.fn.bufload(bufnr)

  local lang = vim.filetype.match({ filename = file }) or "lua"

  local funcs = ast.get_functions(bufnr, lang) or {}

  local out = {}

  for _, f in ipairs(funcs) do
    table.insert(out, {
      name = f.name or "anonymous",
      range = f.range,
    })
  end

  return out
end

-----------------------------------------------------
-- GRAPH CONTEXT
-- FIX #1: graph.impact() does not exist.
-- The real function is graph.get_impacted_files(name).
-- We now call it per-symbol resolved from the query,
-- and build the same shape the rest of the code expects.
-----------------------------------------------------
local function build_graph_context(query)
  local impacted_files = graph.get_impacted_files(query) or {}

  -- Build a structure that mirrors what callers expected from impact()
  return {
    impacted = impacted_files,
    levels = {},  -- get_impacted_files is flat (1-hop); levels left for future LSP upgrade
  }
end

-----------------------------------------------------
-- MAIN EXPLAIN (V2)
-----------------------------------------------------
function M.explain(query)
  if not query or query == "" then
    return {
      ok = false,
      error = "EMPTY_QUERY"
    }
  end

  ---------------------------------------------------
  -- 1. SEMANTIC RESOLUTION
  ---------------------------------------------------
  local resolved = semantic.resolve(query)
  local files = resolved.files or {}
  local symbols = resolved.symbols or {}

  if #files == 0 then
    return {
      ok = false,
      error = "NO_SEMANTIC_MATCH",
      query = query
    }
  end

  ---------------------------------------------------
  -- 2. RANK FILES
  ---------------------------------------------------
  local ranked = ranker.rank(files, query, symbols)

  if not ranked or not ranked.best then
    return {
      ok = false,
      error = "RANKING_FAILED",
    }
  end

  local primary = ranked.best

  ---------------------------------------------------
  -- 3. SUPPORTING FILES
  ---------------------------------------------------
  local supporting = {}

  for i, f in ipairs(ranked.ranking or {}) do
    if i > 1 and i <= 5 then
      table.insert(supporting, f.file)
    end
  end

  ---------------------------------------------------
  -- 4. GRAPH CONTEXT (fixed)
  ---------------------------------------------------
  local graph_ctx = build_graph_context(query)

  ---------------------------------------------------
  -- 5. LOAD PRIMARY CONTENT
  ---------------------------------------------------
  local content = safe_read(primary)

  ---------------------------------------------------
  -- 6. STRUCTURE (AST)
  ---------------------------------------------------
  local functions = extract_functions(primary)

  ---------------------------------------------------
  -- 7. WHY THIS FILE
  ---------------------------------------------------
  local why = ranker.explain_choice and ranker.explain_choice(ranked) or "top ranked by semantic score"

  ---------------------------------------------------
  -- 8. RETURN FULL REASONING PACKET
  ---------------------------------------------------
  return {
    ok = true,

    primary_file = primary,
    supporting_files = supporting,

    ranked_files = ranked.ranking,

    reasoning = {
      why_this_file = why,
      graph = graph_ctx,
      symbols = symbols,
    },

    structure = {
      functions = functions,
    },

    content = content,
  }
end

-----------------------------------------------------
-- MULTI FILE EXPLAIN
-----------------------------------------------------
function M.explain_multi(query)
  local resolved = semantic.resolve(query)
  local files = resolved.files or {}
  local symbols = resolved.symbols or {}

  local ranked = ranker.rank(files, query, symbols)

  local bundle = {}

  for i, f in ipairs(ranked.ranking or {}) do
    if i > 5 then break end

    table.insert(bundle, {
      file = f.file,
      score = f.score,
      reasons = f.reasons,
      content = safe_read(f.file),
    })
  end

  return {
    ok = true,
    files = bundle,
  }
end

return M

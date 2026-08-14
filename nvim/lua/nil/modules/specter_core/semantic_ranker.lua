local semantic = require("nil.modules.specter_core.semantic")
local M = {}

local WEIGHTS = {
  workspace_match = 1000,
  exact_filename = 100,
  query_match = 50,
  symbol_match = 75,   -- FIX #6: new weight for LSP symbol hits in this file
}

local function get_score(file, query, symbol_set)
  local score = 0
  local reasons = {}
  local file_hint, dir_hint = semantic.extract_intent(query)

  local abs_path = file:lower()
  local filename = (file:match("([^/]+)$") or ""):lower()

  if dir_hint then
    local escaped = dir_hint:gsub("%-", "%%-"):lower()
    if abs_path:find("/" .. escaped .. "/", 1, false) then
      score = score + WEIGHTS.workspace_match
      table.insert(reasons, "dir_match:" .. dir_hint)
    end
  end

  if file_hint and filename == file_hint:lower() then
    score = score + WEIGHTS.exact_filename
    table.insert(reasons, "exact_file")
  end

  if query:lower():find(filename, 1, true) then
    score = score + WEIGHTS.query_match
    table.insert(reasons, "query_match")
  end

  -- FIX #6: symbol_set is the third arg passed by semantic_explainer.
  -- Previously it was silently ignored. Now: if any LSP symbol lives
  -- in this file, boost its score — it's a strong relevance signal.
  if symbol_set and type(symbol_set) == "table" then
    for _, sym in ipairs(symbol_set) do
      local sym_file = sym.location and sym.location.uri and vim.uri_to_fname(sym.location.uri)
      if sym_file and vim.fn.fnamemodify(sym_file, ":p"):lower() == vim.fn.fnamemodify(file, ":p"):lower() then
        score = score + WEIGHTS.symbol_match
        table.insert(reasons, "lsp_symbol:" .. (sym.name or "?"))
      end
    end
  end

  local _, depth = file:gsub("/", "")
  score = score - depth

  return score, reasons
end

-----------------------------------------------------
-- RANK
-- FIX #6: signature was rank(files, query) but callers
-- pass rank(files, query, symbols). The symbols table
-- is now forwarded to get_score() as a scoring signal.
-----------------------------------------------------
function M.rank(files, query, symbols)
  if not files or #files == 0 then return { best = nil, ranking = {}, is_ambiguous = false } end

  local scored = {}
  for _, f in ipairs(files) do
    local score, reasons = get_score(f, query, symbols)
    table.insert(scored, { file = f, score = score, reasons = reasons })
  end

  table.sort(scored, function(a, b)
    if a.score ~= b.score then return a.score > b.score end
    return #a.file < #b.file
  end)

  local is_ambiguous = false
  local candidates = { scored[1] }

  if #scored > 1 and scored[1].score == scored[2].score and scored[1].score > 0 then
    is_ambiguous = true
    for i = 2, #scored do
      if scored[i].score == scored[1].score then
        table.insert(candidates, scored[i])
      end
    end
  end

  return {
    best = is_ambiguous and nil or scored[1].file,
    ranking = scored,
    is_ambiguous = is_ambiguous,
    candidates = candidates
  }
end

-----------------------------------------------------
-- EXPLAIN CHOICE (used by semantic_explainer)
-----------------------------------------------------
function M.explain_choice(ranked)
  if not ranked or not ranked.ranking or #ranked.ranking == 0 then
    return "no files ranked"
  end
  local top = ranked.ranking[1]
  if not top then return "unknown" end
  local reasons = top.reasons or {}
  if #reasons == 0 then return "ranked by path depth" end
  return table.concat(reasons, ", ")
end

return M

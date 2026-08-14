local core = require("nil.modules.specter_core.core_model")
local semantic_graph = require("nil.modules.specter_core.semantic_graph")

local M = {}

local function extract_path(args)
  if type(args) == "table" then return args.path or args.file end
  return nil
end

function M.ingest(tool_result)
  if not tool_result then return end
  local tool = tool_result.tool
  local args = tool_result.args or {}
  local result = tool_result.result

  if tool == "repo.read" then
    local path = extract_path(args)
    if path and type(result) == "string" then
      if core.add_file then core.add_file(path, { content = result, source = "repo.read" }) end
      local bufnr = vim.fn.bufadd(path)
      vim.fn.bufload(bufnr)
      local lang = vim.filetype.match({ filename = path }) or "lua"
      semantic_graph.index_file(bufnr, lang, path)
    end
  end

  if tool == "repo.search" then
    if core.add_search then core.add_search(args.query, result) end
    if type(result) == "table" and result.results then
      for _, r in ipairs(result.results) do
        if r.path then
          local bufnr = vim.fn.bufadd(r.path)
          vim.fn.bufload(bufnr)
          local lang = vim.filetype.match({ filename = r.path }) or "lua"
          semantic_graph.index_file(bufnr, lang, r.path)
        end
      end
    end
  end

  -- 🔥 FIX: Store the high-level teacher summary
  if tool == "llm.summarize" and result ~= "PROMPT_MODE" then
    if core.add_file_metadata then
      core.add_file_metadata(args.path or "last_summary", {
        summary = result,
        type = "teaching_analysis"
      })
    end
  end

  if tool == "repo.list" and core.add_structure then
    core.add_structure({ input = args.path, result = result })
  end
end

return M

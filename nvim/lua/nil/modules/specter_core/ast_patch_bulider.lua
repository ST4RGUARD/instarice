local ast = require("nil.modules.specter_core.ast")
local code_llm = require("nil.modules.specter_core.code_edit_llm")

local M = {}

-----------------------------------------------------
-- EXTRACT TEXT FROM LLM RESPONSE
-----------------------------------------------------
local function extract_text(res)
  if not res then return nil end

  if type(res) == "string" then
    return res
  end

  if type(res) == "table" then
    -- common LLM response shapes
    if res.content then return res.content end
    if res.body then return res.body end
    if res.text then return res.text end

    -- anthropic-style fallback
    if res[1] and res[1].text then
      return res[1].text
    end
  end

  return nil
end

-----------------------------------------------------
-- SANITIZE LLM OUTPUT
-----------------------------------------------------
local function sanitize_output(text)
  if not text or text == "" then return nil end

  -- remove code fences safely
  text = text:gsub("^```[%w_]*\n", "")
  text = text:gsub("\n```$", "")
  text = text:gsub("^```[%w_]*", "")
  text = text:gsub("```$", "")

  return text
end

-----------------------------------------------------
-- BUILD PATCH FROM FUNCTION EDIT
-----------------------------------------------------
function M.build(bufnr, lang, function_name, instruction)
  ---------------------------------------------------
  -- GET FUNCTION FROM AST
  ---------------------------------------------------
  local func = ast.extract_function(bufnr, lang, function_name)

  if not func or not func.code then
    return nil, "function not found"
  end

  ---------------------------------------------------
  -- CALL LLM
  ---------------------------------------------------
  local raw = code_llm.edit_function(func.code, instruction)

  local edited = sanitize_output(extract_text(raw))

  if not edited or edited == "" then
    return nil, "LLM returned empty result"
  end

  ---------------------------------------------------
  -- NO-OP GUARD
  ---------------------------------------------------
  if edited == func.code then
    return nil, "no changes produced"
  end

  ---------------------------------------------------
  -- RANGE SAFETY
  ---------------------------------------------------
  local start_row = func.range and func.range.start_row or 0
  local end_row = func.range and func.range.end_row or start_row

  if end_row < start_row then
    end_row = start_row
  end

  ---------------------------------------------------
  -- BUILD PATCH
  ---------------------------------------------------
  return {
    start_line = start_row,
    end_line = end_row,
    new_lines = vim.split(edited, "\n"),
    reason = instruction,
    meta = {
      function_name = function_name,
      lang = lang,
    }
  }
end

return M

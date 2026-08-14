local ast_patch_builder = require("nil.modules.specter_core.ast_patch_builder")
local workspace = require("nil.modules.specter_core.workspace")

local M = {}

-----------------------------------------------------
-- FUNCTION EDIT TOOL (AST + LLM → PATCH)
-----------------------------------------------------
function M.edit_function(bufnr, lang, file, function_name, instruction)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  lang = lang or vim.bo.filetype

  if not file then
    return {
      ok = false,
      error = "missing file"
    }
  end

  if not function_name or function_name == "" then
    return {
      ok = false,
      error = "missing function name"
    }
  end

  if not instruction or instruction == "" then
    return {
      ok = false,
      error = "missing instruction"
    }
  end

  ---------------------------------------------------
  -- BUILD PATCH (AST → LLM → PATCH)
  ---------------------------------------------------
  local patch, err = ast_patch_builder.build(
    bufnr,
    lang,
    function_name,
    instruction
  )

  if not patch then
    return {
      ok = false,
      error = err or "patch build failed"
    }
  end

  ---------------------------------------------------
  -- STORE IN WORKSPACE
  ---------------------------------------------------
  local ok, store_err = workspace.add(file, patch)

  if not ok then
    return {
      ok = false,
      error = store_err or "workspace store failed"
    }
  end

  return {
    ok = true,
    file = file,
    function_name = function_name,
    patch = patch,
  }
end

return M

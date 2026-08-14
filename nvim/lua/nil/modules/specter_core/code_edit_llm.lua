local api = require("nil.modules.specter_core.api")

local M = {}

-----------------------------------------------------
-- ASK LLM TO EDIT A FUNCTION ONLY
-----------------------------------------------------
function M.edit_function(func_code, instruction)
  local prompt = [[
You are a code editing system.

RULES:
- Modify ONLY the given function
- Do NOT output explanations
- Output ONLY the full updated function
- Keep syntax valid
- Preserve function name

TASK:
]] .. instruction .. [[

FUNCTION:
]] .. func_code

  local res = api.request({
    model = "claude-opus-4-5",
    max_tokens = 800,
    messages = {
      {
        role = "user",
        content = prompt
      }
    }
  })

  return res
end

return M

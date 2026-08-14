local M = {}

M.config = {
  confirm_patch = true,
  confirm_plan = false,
}

local function confirm(msg)
  local choice = vim.fn.confirm(msg, "&Yes\n&No", 2)
  return choice == 1
end

function M.allow(tool, args)
  args = args or {}

  if tool == "plan" then
    if M.config.confirm_plan then
      return confirm("Execute agent plan?")
    end
    return true
  end

  if tool == "apply_patch" then
    if not M.config.confirm_patch then
      return true
    end

    -- FIX: avoid nil file spam
    local target =
      args.file
      or args.scope
      or "workspace"

    return confirm("Apply patch to:\n" .. tostring(target))
  end

  return true
end

return M

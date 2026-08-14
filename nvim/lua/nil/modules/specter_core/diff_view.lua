local workspace = require("nil.modules.specter_core.workspace")
local M = {}

function M.show()
  local diff_text = workspace.get_unified_diff()
  if diff_text == "" then
    print("Specter: No staged patches to show.")
    return
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, vim.split(diff_text, "\n"))

  vim.cmd("vsplit")
  vim.api.nvim_set_current_buf(bufnr)

  vim.bo[bufnr].filetype   = "diff"
  vim.bo[bufnr].buftype    = "nofile"
  vim.bo[bufnr].bufhidden  = "wipe"
  vim.bo[bufnr].modifiable = true   -- allow the user to delete + lines

  vim.keymap.set("n", "q", ":q<CR>", { buffer = bufnr })

  vim.keymap.set("n", "<CR>", function()
    -------------------------------------------------------
    -- Parse the (possibly edited) diff buffer to rebuild
    -- the workspace from only the patches the user kept.
    -- Any + line that was deleted before hitting Enter will
    -- simply not appear here and won't be applied.
    -------------------------------------------------------
    local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Wipe the current workspace — we'll re-populate from the buffer
    workspace.clear()

    local current_file = nil
    local current_patch = nil   -- { start_line, end_line, new_lines, reason }

    local function flush_patch()
      if current_file and current_patch and #current_patch.new_lines > 0 then
        workspace.add(current_file, current_patch)
      end
      current_patch = nil
    end

    for _, line in ipairs(buf_lines) do
      -- New file header
      if line:match("^%+%+%+ b/") then
        flush_patch()
        current_file = line:sub(7)   -- strip "+++ b/"

      -- Hunk header  @@ -old,n +new,n @@ reason
      elseif line:match("^@@") then
        flush_patch()
        -- Extract the new-side start line (1-indexed in diff, 0-indexed in workspace)
        local new_start = tonumber(line:match("%+(%d+)")) or 1
        local reason    = line:match("@@%s*(.-)%s*$") or ""
        current_patch = {
          start_line = new_start - 1,
          end_line   = new_start - 1,
          new_lines  = {},
          reason     = reason,
        }

      -- Added line — kept by the user
      elseif line:match("^%+") and current_patch then
        table.insert(current_patch.new_lines, line:sub(2))

      -- Removed line — just context for display, skip
      -- Context line — skip
      end
    end

    flush_patch()

    vim.cmd("q")

    if vim.tbl_count(workspace.list()) == 0 then
      vim.notify("Specter: All patches removed — nothing to apply.")
      return
    end

    workspace.apply_all()
  end, { buffer = bufnr })

  print("Specter: Edit diff, delete unwanted + lines, then [Enter] to commit or [q] to cancel.")
end

return M

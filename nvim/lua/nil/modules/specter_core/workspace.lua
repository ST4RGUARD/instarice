local patch_engine = require("nil.modules.specter_core.patch_engine")
local M = {}

M.patches = {}
M.root = vim.fn.getcwd()

function M.add(file, patch)
  if not file or not patch then return false, "invalid patch input" end
  if not M.patches[file] then M.patches[file] = { list = {} } end

  table.insert(M.patches[file].list, {
    start_line = patch.start_line,
    end_line = patch.end_line,
    new_lines = patch.new_lines,
    reason = patch.reason or "unspecified",
    meta = patch.meta or {},
  })
  return true
end

function M.resolve(query, ctx)
  if not query or query == "" then return nil end
  local root = (ctx and ctx.cwd) or M.root

  if vim.fn.filereadable(query) == 1 then
    return { file = query, confidence = 1.0 }
  end

  local files = vim.fn.systemlist({ "rg", "--files", root })
  local best = nil
  local best_score = -100

  for _, f in ipairs(files) do
    local score = 0
    local abs_f = root .. "/" .. f:gsub("^./", "")
    local filename = f:match("([^/]+)$") or ""

    if filename:lower() == query:lower() then
      score = score + 50
    elseif f:lower():find(query:lower(), 1, true) then
      score = score + 10
    end

    local _, depth = f:gsub("/", "")
    score = score - depth

    if score > best_score then
      best_score = score
      best = abs_f
    end
  end

  if not best then
    return { file = nil, error = "NO_MATCH", query = query }
  end

  return { file = best, confidence = math.min(1.0, best_score / 50) }
end

-- Helper for the Diff View
-- Reads the original file, diffs line-by-line against new_lines,
-- and shows only the changed lines plus CONTEXT lines around them.
function M.get_unified_diff()
  local CONTEXT = 6
  local out = {}

  for file, entry in pairs(M.patches) do
    table.insert(out, "--- a/" .. file)
    table.insert(out, "+++ b/" .. file)

    local original = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file) or {}

    local sorted = vim.deepcopy(entry.list)
    table.sort(sorted, function(a, b) return a.start_line < b.start_line end)

    for _, p in ipairs(sorted) do
      local old_start  = p.start_line   -- 0-indexed
      local old_end    = p.end_line     -- 0-indexed inclusive
      local old_lines  = {}
      for i = old_start, old_end do
        table.insert(old_lines, original[i + 1] or "")
      end
      local new_lines = p.new_lines or {}

      -- Line-by-line diff: find which indices actually changed
      -- We align old and new by index; any line that differs is "changed"
      local max_len = math.max(#old_lines, #new_lines)
      local changed = {}   -- set of 0-based offsets within the patch that differ
      for i = 1, max_len do
        if old_lines[i] ~= new_lines[i] then
          changed[i - 1] = true
        end
      end

      -- If nothing changed (identical), skip this patch entirely
      if not next(changed) then goto continue end

      -- Build a set of line offsets to show: changed lines + CONTEXT around them
      local show = {}
      for offset, _ in pairs(changed) do
        for c = math.max(0, offset - CONTEXT), math.min(max_len - 1, offset + CONTEXT) do
          show[c] = true
        end
      end

      -- Sort offsets
      local offsets = {}
      for o in pairs(show) do table.insert(offsets, o) end
      table.sort(offsets)

      -- Emit hunks — group consecutive offsets together
      local i = 1
      while i <= #offsets do
        -- Find the end of this consecutive group
        local group_start = offsets[i]
        local group_end   = offsets[i]
        while i + 1 <= #offsets and offsets[i + 1] == offsets[i] + 1 do
          i = i + 1
          group_end = offsets[i]
        end

        -- Count old and new lines in this group
        local hunk_old_count = 0
        local hunk_new_count = 0
        for o = group_start, group_end do
          if old_lines[o + 1] then hunk_old_count = hunk_old_count + 1 end
          if new_lines[o + 1] then hunk_new_count = hunk_new_count + 1 end
          if not old_lines[o + 1] and new_lines[o + 1] then hunk_new_count = hunk_new_count + 1 end
        end

        table.insert(out, string.format(
          "@@ -%d,%d +%d,%d @@ %s",
          old_start + group_start + 1,
          hunk_old_count,
          old_start + group_start + 1,
          hunk_new_count,
          p.reason or ""
        ))

        for o = group_start, group_end do
          local old_l = old_lines[o + 1]
          local new_l = new_lines[o + 1]
          if changed[o] then
            if old_l then table.insert(out, "-" .. old_l) end
            if new_l then table.insert(out, "+" .. new_l) end
          else
            -- context line — use old (they're identical)
            if old_l then table.insert(out, " " .. old_l) end
          end
        end

        i = i + 1
      end

      ::continue::
    end

    table.insert(out, "")
  end

  return table.concat(out, "\n")
end

function M.list_files() return vim.fn.systemlist({ "rg", "--files", M.root }) end
function M.list() return M.patches end

local function apply_file(file, entry)
  local buf = vim.fn.bufadd(file)
  vim.fn.bufload(buf)
  
  -- Sort patches descending to avoid line-shift issues during multi-patch apply
  table.sort(entry.list, function(a, b) return a.start_line > b.start_line end)

  for _, patch in ipairs(entry.list or {}) do
    local ok, err = patch_engine.apply(buf, patch)
    if not ok then return false, err end
  end
  vim.api.nvim_buf_call(buf, function() vim.cmd("write") end)
  return true
end

function M.apply_all()
  if vim.tbl_count(M.patches) == 0 then return true end
  for file, entry in pairs(M.patches) do
    local ok, err = apply_file(file, entry)
    if not ok then 
      print("Error applying " .. file .. ": " .. tostring(err))
      return false 
    end
  end
  M.clear()
  print("✅ Workspace committed to disk.")
  return true
end

function M.clear() M.patches = {} end

return M

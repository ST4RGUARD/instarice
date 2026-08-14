local api    = require 'nil.modules.specter_core.api'
local config = require 'nil.modules.specter_core.config'

local M = {}

M.enabled = false
M.ns = vim.api.nvim_create_namespace 'claude_inline'

M.timer = nil
M.last_request_id = 0
M.suggestion = nil

-----------------------------------------------------
-- SETUP
-----------------------------------------------------
function M.setup(cfg)
  M.config = cfg or {}

  vim.api.nvim_create_autocmd("TextChangedI", {
    callback = function()
      if not M.enabled then return end
      M.trigger()
    end,
  })

  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      M.clear()
    end,
  })

  vim.keymap.set("i", "<C-a>", function()
    if M.suggestion then
      M.accept()
      return ""
    end
    return "<C-a>"
  end, { expr = true, noremap = true })
end

-----------------------------------------------------
-- CLEAR
-----------------------------------------------------
function M.clear()
  M.suggestion = nil
  vim.api.nvim_buf_clear_namespace(0, M.ns, 0, -1)
end

-----------------------------------------------------
-- CONTEXT
-----------------------------------------------------
local function get_context()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local start_row = math.max(0, row - 20)
  local lines = vim.api.nvim_buf_get_lines(0, start_row, row, false)
  local current_line = vim.api.nvim_get_current_line()
  return table.concat(lines, '\n') .. '\n' .. current_line
end

-----------------------------------------------------
-- RENDER (MULTI-LINE)
-----------------------------------------------------
function M.render(text)
  if not text or text == '' then return end

  M.suggestion = text

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local lines = vim.split(text, '\n')

  vim.api.nvim_buf_set_extmark(0, M.ns, row - 1, col, {
    virt_text = { { lines[1], 'Comment' } },
    virt_text_pos = 'overlay',
  })

  if #lines > 1 then
    vim.api.nvim_buf_set_extmark(0, M.ns, row, 0, {
      virt_lines = vim.tbl_map(function(l)
        return { { l, 'Comment' } }
      end, vim.list_slice(lines, 2)),
    })
  end
end

-----------------------------------------------------
-- TRIGGER (DEBOUNCED)
-----------------------------------------------------
function M.trigger()
  if not M.enabled then return end

  if M.timer then
    M.timer:stop()
    M.timer:close()
    M.timer = nil
  end

  M.timer = vim.loop.new_timer()
  M.timer:start(120, 0, vim.schedule_wrap(function()
    M.request()
  end))
end

-----------------------------------------------------
-- REQUEST (COPILOT STYLE)
-----------------------------------------------------
function M.request()
  M.clear()

  local ok, ctx = pcall(get_context)
  if not ok or not ctx then return end

  local request_id = M.last_request_id + 1
  M.last_request_id = request_id

  -- Uses config.inline_model so switching model is a one-line change in config.lua
  api.request_async({
    model      = M.config.model or config.inline_model or 'claude-opus-4-5',
    max_tokens = 120,
    messages   = {
      {
        role    = 'user',
        content = table.concat({
          'You are a code completion engine like Copilot.',
          'Continue the code naturally.',
          'Return ONLY continuation text.',
          'Do not repeat input.',
          '',
          ctx,
        }, '\n'),
      },
    },
  }, function(response)
    if request_id ~= M.last_request_id then return end
    response = response:gsub('^```.-\n', ''):gsub('```$', ''):gsub('^%s+', '')
    M.render(response)
  end)
end

-----------------------------------------------------
-- ACCEPT
-----------------------------------------------------
function M.accept()
  if not M.suggestion then return '<Tab>' end

  local text = M.suggestion
  M.clear()

  vim.schedule(function()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, vim.split(text, '\n'))
  end)

  return ''
end

-----------------------------------------------------
-- TOGGLE
-----------------------------------------------------
function M.toggle()
  M.enabled = not M.enabled
  print('Specter inline: ' .. (M.enabled and 'ON' or 'OFF'))
  if not M.enabled then M.clear() end
end

-----------------------------------------------------
-- REFACTOR SELECTION (staged diff review)
-- Highlight code → <leader>fd or :SpecterRefactor
-- Optional instruction, otherwise uses sensible default.
-----------------------------------------------------
function M.refactor_selection(instruction)
  local workspace = require("nil.modules.specter_core.workspace")
  local diff_view = require("nil.modules.specter_core.diff_view")

  local start_line = vim.fn.line("'<")
  local end_line   = vim.fn.line("'>")

  if start_line <= 0 or end_line <= 0 or start_line > end_line then
    vim.notify("[Specter] No valid selection.", vim.log.levels.WARN)
    return
  end

  local lines  = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local code   = table.concat(lines, "\n")
  local bufnr  = vim.api.nvim_get_current_buf()
  local file   = vim.api.nvim_buf_get_name(bufnr)
  local lang   = vim.bo[bufnr].filetype

  if code:match("^%s*$") then
    vim.notify("[Specter] Selection is empty.", vim.log.levels.WARN)
    return
  end

  instruction = (instruction and instruction ~= "") and instruction
    or "Fix any syntax errors, bugs, and improve readability. Keep behaviour identical."

  local model = config.refactor_model or "claude-opus-4-5"

  local prompt = table.concat({
    "You are an expert " .. lang .. " developer.",
    "",
    "Task: " .. instruction,
    "",
    "Rules:",
    "- Return ONLY the fixed/refactored code",
    "- No explanations, no markdown fences, no extra text",
    "- Preserve indentation style of the original",
    "- Keep the same number of lines where possible",
    "- Do not change behaviour unless fixing a bug",
    "",
    "CODE:",
    code,
  }, "\n")

  vim.notify("[Specter] Refactoring selection... (" .. model .. ")", vim.log.levels.INFO)

  api.request_async({
    model      = model,
    max_tokens = 2048,
    messages   = {{ role = "user", content = prompt }},
  }, function(response)
    if not response or response == "" then
      vim.notify("[Specter] Empty response from API.", vim.log.levels.ERROR)
      return
    end
    if response:match("^%[Claude error") or response:match("^%[Claude HTTP") then
      vim.notify("[Specter] API error: " .. response, vim.log.levels.ERROR)
      return
    end

    response = response:gsub("^```[%w_]*%s*\n?", "")
                       :gsub("\n?```%s*$", "")
                       :gsub("^%s+", "")

    local new_lines = vim.split(response, "\n")

    local ok, err = workspace.add(file, {
      start_line = start_line - 1,
      end_line   = end_line - 1,
      new_lines  = new_lines,
      reason     = "refactor: " .. instruction:sub(1, 60),
    })

    if not ok then
      vim.notify("[Specter] Failed to stage patch: " .. tostring(err), vim.log.levels.ERROR)
      return
    end

    vim.notify("[Specter] Refactor staged. Reviewing diff...", vim.log.levels.INFO)
    diff_view.show()
  end)
end

-----------------------------------------------------
-- REFACTOR IN PLACE (direct buffer write, no review)
-- Highlight code → <leader>fi or :SpecterFix
-----------------------------------------------------
function M.refactor_inplace(instruction)
  local start_line = vim.fn.line("'<")
  local end_line   = vim.fn.line("'>")

  if start_line <= 0 or end_line <= 0 or start_line > end_line then
    vim.notify("[Specter] No valid selection.", vim.log.levels.WARN)
    return
  end

  local lines  = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)
  local code   = table.concat(lines, "\n")
  local bufnr  = vim.api.nvim_get_current_buf()
  local lang   = vim.bo[bufnr].filetype

  if code:match("^%s*$") then
    vim.notify("[Specter] Selection is empty.", vim.log.levels.WARN)
    return
  end

  instruction = (instruction and instruction ~= "") and instruction
    or "Fix any syntax errors, bugs, and improve readability. Keep behaviour identical."

  local model = config.refactor_model or "claude-opus-4-5"

  local prompt = table.concat({
    "You are an expert " .. lang .. " developer.",
    "",
    "Task: " .. instruction,
    "",
    "Rules:",
    "- Return ONLY the fixed/refactored code",
    "- No explanations, no markdown fences, no extra text",
    "- Preserve indentation style of the original",
    "- Keep the same number of lines where possible",
    "- Do not change behaviour unless fixing a bug",
    "",
    "CODE:",
    code,
  }, "\n")

  vim.notify("[Specter] Fixing in place... (" .. model .. ")", vim.log.levels.INFO)

  api.request_async({
    model      = model,
    max_tokens = 2048,
    messages   = {{ role = "user", content = prompt }},
  }, function(response)
    if not response or response == "" or
       response:match("^%[Claude error") or response:match("^%[Claude HTTP") then
      vim.notify("[Specter] API error: " .. tostring(response), vim.log.levels.ERROR)
      return
    end

    response = response:gsub("^```[%w_]*%s*\n?", "")
                       :gsub("\n?```%s*$", "")
                       :gsub("^%s+", "")

    local new_lines = vim.split(response, "\n")

    vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, new_lines)
    vim.notify("[Specter] Applied in place.", vim.log.levels.INFO)
  end)
end

-----------------------------------------------------
-- CONVENIENCE WRAPPERS
-----------------------------------------------------
function M.fix_selection()
  M.refactor_selection("Fix all syntax errors, type errors, and obvious bugs. Keep behaviour identical.")
end

function M.fix_inplace()
  M.refactor_inplace("Fix all syntax errors, type errors, and obvious bugs. Keep behaviour identical.")
end

return M

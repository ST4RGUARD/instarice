local agent = require("nil.modules.specter_core.agent")
local ui = require("nil.modules.specter_core.ui")

local M = {}

-----------------------------------------------------
-- BUFFERS & STATE
-----------------------------------------------------
local log_buf = nil
local input_buf = nil
local win_log = nil
local win_input = nil
local thinking_timer = nil
local thinking_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

-----------------------------------------------------
-- LOGGING UTILS
-----------------------------------------------------
local function append_log(text)
  if not log_buf or not vim.api.nvim_buf_is_valid(log_buf) then return end
  local lines = vim.split(tostring(text or ""), "\n", { plain = true })
  vim.api.nvim_buf_set_lines(log_buf, -1, -1, false, lines)
  
  if win_log and vim.api.nvim_win_is_valid(win_log) then
    local line_count = vim.api.nvim_buf_line_count(log_buf)
    vim.api.nvim_win_set_cursor(win_log, { line_count, 0 })
  end
end

-----------------------------------------------------
-- THINKING ANIMATION
-----------------------------------------------------
local function stop_thinking()
  if thinking_timer then
    thinking_timer:stop()
    thinking_timer:close()
    thinking_timer = nil
  end
  
  -- Schedule the UI cleanup to ensure it happens on the next tick
  vim.schedule(function()
    if log_buf and vim.api.nvim_buf_is_valid(log_buf) then
      -- Wipe the spinner line at index 2
      vim.api.nvim_buf_set_lines(log_buf, 2, 3, false, { "" })
      vim.cmd("redraw")
    end
  end)
end

local function start_thinking()
  if thinking_timer then stop_thinking() end
  local frame = 1
  
  -- Write initial state
  vim.api.nvim_buf_set_lines(log_buf, 2, 3, false, { " 🧠 Thinking..." })
  vim.cmd("redraw") 

  thinking_timer = vim.loop.new_timer()
  thinking_timer:start(0, 80, vim.schedule_wrap(function()
    if not log_buf or not vim.api.nvim_buf_is_valid(log_buf) then 
      stop_thinking()
      return 
    end
    local spinner = thinking_frames[frame]
    vim.api.nvim_buf_set_lines(log_buf, 2, 3, false, { " 🧠 Thinking " .. spinner })
    vim.cmd("redraw") 
    frame = (frame % #thinking_frames) + 1
  end))
end

-----------------------------------------------------
-- UI LAYOUT
-----------------------------------------------------
local function open_window()
  if log_buf and vim.api.nvim_buf_is_valid(log_buf) then return end

  vim.cmd("vsplit")
  win_log = vim.api.nvim_get_current_win()
  log_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win_log, log_buf)

  vim.bo[log_buf].buftype = "nofile"
  vim.bo[log_buf].syntax = "markdown" 

  vim.api.nvim_buf_set_lines(log_buf, 0, -1, false, {
    " 🧠 Specter Agent",
    " ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    "", -- Index 2 (Spinner)
    "",
    "",
  })

  vim.cmd("split")
  win_input = vim.api.nvim_get_current_win()
  input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win_input, input_buf)

  vim.bo[input_buf].buftype = "prompt"
  vim.fn.prompt_setprompt(input_buf, "❯ ")

  -- Register callbacks, including the new 'done' trigger
  ui.register({
    log = M.log,
    step = M.step,
    tool = M.tool,
    result = M.result,
    done = function() 
      stop_thinking() 
    end
  })

  vim.keymap.set("i", "<CR>", function()
    local input = M.get_input()
    if input == "" or input == "❯ " then return end

    append_log("❯ " .. input)
    M.clear_input()
    
    start_thinking()

    -- Give the UI loop 100ms to start the spinner before the agent blocks the thread
    vim.defer_fn(function()
        vim.schedule(function()
            agent.run(input)
        end)
    end, 100) 
    
  end, { buffer = input_buf })
end

function M.run()
  open_window()
end

function M.get_input()
  if not input_buf or not vim.api.nvim_buf_is_valid(input_buf) then return "" end
  local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
  local str = table.concat(lines, "\n")
  return str:gsub("^❯%s*", "")
end

function M.clear_input()
  if input_buf and vim.api.nvim_buf_is_valid(input_buf) then
    vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, { "" })
  end
end

-----------------------------------------------------
-- UI CALLBACKS
-----------------------------------------------------
function M.log(msg)
  append_log(msg)
end

function M.step(i)
  append_log("🔹 Step " .. i)
end

function M.tool(t)
  append_log("🔧 TOOL: " .. tostring(t.tool))
end

function M.result(res)
  append_log("📦 RESULT:")
  if type(res) == "string" then
    append_log(res)
  else
    append_log(vim.inspect(res))
  end
  append_log("---")
end

return M

local api = require 'nil.modules.specter_core.api'
local config = require 'nil.modules.specter_core.config'
local handle = os.getenv 'handle'

local M = {}

-- joke
-----------------------------------------------------
-- CONFIG
-----------------------------------------------------
M.config = config

local chat_buf = nil
local messages = {}
local request_id = 0

-----------------------------------------------------
-- SETUP
-----------------------------------------------------
function M.setup(cfg)
  M.config = vim.tbl_deep_extend('force', M.config, cfg or {})
end

-----------------------------------------------------
-- WINDOW MANAGEMENT
-----------------------------------------------------
local function open_chat_window()
  if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
    vim.api.nvim_set_current_buf(chat_buf)
    return chat_buf
  end

  vim.cmd 'vsplit'
  vim.cmd 'vertical resize 80'

  chat_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(chat_buf, 'Specter Chat')

  vim.bo[chat_buf].buftype = 'nofile'
  vim.bo[chat_buf].bufhidden = 'hide'
  vim.bo[chat_buf].swapfile = false
  vim.bo[chat_buf].filetype = 'markdown'
  vim.bo[chat_buf].modifiable = true

  vim.api.nvim_set_current_buf(chat_buf)

  vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, {
    '💬 Specter Chat',
    '****************************',
    '',
    '❯  ',
    '',
  })

  vim.api.nvim_win_set_cursor(0, { 4, 6 })

  return chat_buf
end

-----------------------------------------------------
-- APPEND
-----------------------------------------------------
local function append(role, text)
  if not chat_buf or not vim.api.nvim_buf_is_valid(chat_buf) then
    return
  end

  local prefix = role == 'user' and ('👤 ' .. handle .. ':') or '🤖 Specter:'
  local lines = vim.split(text or '', '\n')

  local out = { '', prefix }
  for _, l in ipairs(lines) do
    table.insert(out, l)
  end

  vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, out)
end

-----------------------------------------------------
-- INPUT
-----------------------------------------------------
local function get_input()
  local lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

  local started = false
  local input = {}

  for _, line in ipairs(lines) do
    if line == '****************************' then
      started = true
    elseif started and line ~= '' then
      table.insert(input, line)
    end
  end

  return table.concat(input, '\n')
end

-----------------------------------------------------
-- SEND
-----------------------------------------------------
function M.send()
  if not chat_buf or not vim.api.nvim_buf_is_valid(chat_buf) then
    return
  end

  local input = get_input()
  if input:match '^%s*$' then
    return
  end

  request_id = request_id + 1
  local current_id = request_id

  append('user', input)

  table.insert(messages, {
    role = 'user',
    content = input,
  })

  append('assistant', '⏳ thinking...')

  api.request_async({
    model = M.config.chat_model or 'claude-opus-4-5',
    messages = messages,
    max_tokens = 800,
  }, function(response)
    if current_id ~= request_id then
      return
    end

    local buf_lines = vim.api.nvim_buf_get_lines(chat_buf, 0, -1, false)

    for i = #buf_lines, 1, -1 do
      if buf_lines[i] == '⏳ thinking...' then
        table.remove(buf_lines, i)
        if i - 1 >= 1 then
          table.remove(buf_lines, i - 1)
        end
        break
      end
    end

    vim.api.nvim_buf_set_lines(chat_buf, 0, -1, false, buf_lines)

    append('assistant', response)

    table.insert(messages, {
      role = 'assistant',
      content = response,
    })

    vim.api.nvim_buf_set_lines(chat_buf, -1, -1, false, {
      '',
      '',
      '❯  ',
    })

    vim.api.nvim_win_set_cursor(0, {
      vim.api.nvim_buf_line_count(chat_buf),
      4,
    })
  end)
end

-----------------------------------------------------
-- PROMPT
-----------------------------------------------------
function M.prompt()
  local buf = open_chat_window()

  vim.keymap.set('n', '<CR>', M.send, {
    buffer = buf,
    desc = 'Send to Specter',
  })
end

-----------------------------------------------------
-- RESET
-----------------------------------------------------
function M.fresh_chat()
  if chat_buf and vim.api.nvim_buf_is_valid(chat_buf) then
    vim.api.nvim_buf_delete(chat_buf, { force = true })
  end

  chat_buf = nil
  messages = {}
  request_id = 0

  M.prompt()
end

return M

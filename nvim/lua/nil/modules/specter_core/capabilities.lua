local api = require("nil.modules.specter_core.api")

-- Load the model configuration
local config_ok, config = pcall(require, "nil.config")
local chat_model = config_ok and config.chat_model or "claude-opus-4-5"

local M = {}

local function prepare_opts(payload)
  local system_prompt = ""
  if payload.systemInstruction and payload.systemInstruction.parts then
    system_prompt = payload.systemInstruction.parts[1].text
  end

  local user_text = ""
  if payload.contents and payload.contents[1] and payload.contents[1].parts then
    user_text = payload.contents[1].parts[1].text
  end

  return {
    model = chat_model,
    max_tokens = payload.max_tokens or nil,  -- forward caller override if set
    messages = {
      { role = "user", content = system_prompt .. "\n\n" .. user_text }
    }
  }
end

-----------------------------------------------------
-- ASYNC GENERATION (non-blocking)
-- Guaranteed callback path with 45s watchdog.
-----------------------------------------------------
function M.generate_async(payload, callback)
  local opts = prepare_opts(payload)
  local has_resolved = false

  local function safe_callback(res)
    if not has_resolved then
      has_resolved = true
      vim.schedule(function() callback(res) end)
    end
  end

  -- Watchdog: force-resume if API hangs
  vim.defer_fn(function()
    if not has_resolved then
      vim.notify("[SPECTER-CAPS] Watchdog triggered after 120s. Forcing resume.", vim.log.levels.WARN)
      safe_callback({ ok = false, text = "⚠️ Error: API timed out or failed to execute." })
    end
  end, 120000)  -- 120s: code generation can take 60-90s through Azure proxy

  local status, err = pcall(function()
    vim.notify("[SPECTER-CAPS] Starting API request for " .. chat_model)
    api.request_async(opts, function(response_text)
      if not response_text or response_text == "" then
        safe_callback({ ok = false, text = "⚠️ Error: Empty response from API." })
      elseif response_text:match("^%[Claude error") or response_text:match("^%[Claude HTTP") then
        safe_callback({ ok = false, text = response_text })
      else
        safe_callback({ ok = true, text = response_text })
      end
    end)
  end)

  if not status then
    vim.notify("[SPECTER-CAPS] Critical API error: " .. tostring(err), vim.log.levels.ERROR)
    safe_callback({ ok = false, text = "⚠️ Internal Error: " .. tostring(err) })
  end
end

-----------------------------------------------------
-- SYNC GENERATION (blocking)
-----------------------------------------------------
function M.generate(payload)
  local opts = prepare_opts(payload)
  local response_text = api.request(opts)
  if response_text:match("^%[Claude error") or response_text:match("^%[Claude HTTP") then
    return { ok = false, text = response_text }
  end
  return { ok = true, text = response_text }
end

return M

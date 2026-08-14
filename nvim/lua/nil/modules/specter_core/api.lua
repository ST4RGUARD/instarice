local curl = require("plenary.curl")

local M = {}

-- jarelian

-----------------------------------------------------
-- OPTIONAL LOGGER HOOK (UI INTEGRATION)
-----------------------------------------------------
M.logger = nil

local function log(msg)
  if M.logger then
    M.logger(msg)
  end
end

-- Azure Proxy Endpoint
local azure_endpoint = "https://ati-ai-models-resource.services.ai.azure.com/anthropic/v1/messages"

-----------------------------------------------------
-- CORE REQUEST (blocking) - Keep for non-UI tasks
-----------------------------------------------------
function M.request(opts)
  opts = opts or {}

  local payload = {
    model = opts.model or "claude-opus-4-5",
    max_tokens = opts.max_tokens or 1024,
    messages = opts.messages or {},
  }

  local body = vim.fn.json_encode(payload)

  log("Request payload (Sync):")
  log(vim.inspect(payload))

  local res = curl.post(azure_endpoint, {
    headers = {
      ["x-api-key"] = os.getenv("AZURE_ANTHROPIC_KEY"),
      ["anthropic-version"] = "2023-06-01",
      ["content-type"] = "application/json",
    },
    body = body,
    timeout = 60000,
  })

  if not res then return "[Claude error: no response]" end
  if res.status ~= 200 then return "[Claude HTTP ERROR " .. tostring(res.status) .. "]: " .. tostring(res.body) end

  local ok, decoded = pcall(vim.json.decode, res.body)
  if not ok then return "[Claude error: invalid JSON]" end
  if decoded.content and decoded.content[1] and decoded.content[1].text then
    return decoded.content[1].text
  end

  return "[Claude error: unexpected response format]"
end

-----------------------------------------------------
-- TRUE ASYNC REQUEST (Non-blocking)
-----------------------------------------------------
function M.request_async(opts, callback)
  opts = opts or {}

  local payload = {
    model = opts.model or "claude-opus-4-5",
    max_tokens = opts.max_tokens or 8192, -- Generous for code generation
    messages = opts.messages or {},
    system = opts.system or "",
  }

  local body = vim.fn.json_encode(payload)
  log("Starting Background Request...")

  -- Using plenary.curl's callback feature makes the call non-blocking
  curl.post(azure_endpoint, {
    headers = {
      ["x-api-key"] = os.getenv("AZURE_ANTHROPIC_KEY"),
      ["anthropic-version"] = "2023-06-01",
      ["content-type"] = "application/json",
    },
    body = body,
    timeout = 120000,  -- 120s to match watchdog
    callback = function(res)
      -- This inner function runs in a separate thread/process managed by plenary
      local final_text = ""

      if not res then
        final_text = "[Claude error: no response from proxy]"
      elseif res.status ~= 200 then
        final_text = "[Claude HTTP ERROR " .. tostring(res.status) .. "]: " .. tostring(res.body)
      else
        local ok, decoded = pcall(vim.json.decode, res.body)
        if not ok then
          final_text = "[Claude error: invalid JSON response]"
        elseif decoded.error then
          final_text = "[Claude API ERROR]: " .. vim.inspect(decoded.error)
        elseif decoded.content and decoded.content[1] and decoded.content[1].text then
          final_text = decoded.content[1].text
        else
          final_text = "[Claude error: unexpected format]"
        end
      end

      -- IMPORTANT: Return to the main thread before calling the UI callback
      vim.schedule(function()
        log("Async request completed.")
        callback(final_text)
      end)
    end,
  })
end

return M

local M = {}

-----------------------------------------------------
-- HANDLERS (default to NOOP but visible if missing)
-----------------------------------------------------
M._log = function(msg)
  print("[UI:log missing] " .. tostring(msg))
end

M._step = function(msg)
  print("[UI:step missing] " .. tostring(msg))
end

M._tool = function(msg)
  print("[UI:tool missing] " .. vim.inspect(msg))
end

M._result = function(msg)
  print("[UI:result missing] " .. vim.inspect(msg))
end

-- 🔥 ADDED: Internal handler for the spinner stop
M._done = function()
  -- Silent noop by default
end

-----------------------------------------------------
-- REGISTER UI HANDLERS
-----------------------------------------------------
function M.register(handlers)
  M._log = handlers.log or M._log
  M._step = handlers.step or M._step
  M._tool = handlers.tool or M._tool
  M._result = handlers.result or M._result
  -- 🔥 ADDED: Register the done handler
  M._done = handlers.done or M._done
end

-----------------------------------------------------
-- PUBLIC API
-----------------------------------------------------
function M.open() end
function M.clear() end

function M.log(msg)
  M._log(msg)
end

function M.step(i)
  M._step(i)
end

function M.tool(action)
  M._tool(action)
end

function M.result(res)
  M._result(res)
end

-- 🔥 ADDED: Public Done API
function M.done()
  M._done()
end

return M

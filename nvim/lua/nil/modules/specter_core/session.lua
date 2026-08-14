local M = {}

local store = require("nil.modules.specter_core.session_store")

M.current = nil

-----------------------------------------------------
-- START SESSION
-----------------------------------------------------
function M.start(input)
  M.current = {
    id = tostring(os.time()),
    input = input,
    messages = {},
    steps = {},
    checkpoints = {},
    status = "running",
    created_at = os.time(),
  }

  store.save(M.current)

  return M.current
end

-----------------------------------------------------
-- GET SESSION
-----------------------------------------------------
function M.get()
  return M.current
end

-----------------------------------------------------
-- ADD MESSAGE (PERSISTED)
-----------------------------------------------------
function M.add_message(msg)
  if not M.current then return end

  table.insert(M.current.messages, msg)

  store.save(M.current)
end

-----------------------------------------------------
-- ADD STEP + CHECKPOINT (PERSISTED)
-----------------------------------------------------
function M.add_step(step_data)
  if not M.current then return end

  table.insert(M.current.steps, step_data)

  table.insert(M.current.checkpoints, {
    step = step_data.step,
    action = step_data.action,
    result = step_data.result,
    timestamp = os.time(),
  })

  store.save(M.current)
end

-----------------------------------------------------
-- GET CHECKPOINT
-----------------------------------------------------
function M.get_checkpoint(step)
  if not M.current then return nil end

  for _, cp in ipairs(M.current.checkpoints) do
    if cp.step == step then
      return cp
    end
  end

  return nil
end

-----------------------------------------------------
-- REWIND SESSION (IN MEMORY ONLY)
-----------------------------------------------------
function M.rewind(step)
  if not M.current then return end

  local new_steps = {}
  local new_checkpoints = {}

  for _, s in ipairs(M.current.steps) do
    if s.step <= step then
      table.insert(new_steps, s)
    end
  end

  for _, cp in ipairs(M.current.checkpoints) do
    if cp.step <= step then
      table.insert(new_checkpoints, cp)
    end
  end

  M.current.steps = new_steps
  M.current.checkpoints = new_checkpoints
  M.current.status = "rewound_to_" .. step

  store.save(M.current)
end

-----------------------------------------------------
-- END SESSION
-----------------------------------------------------
function M.end_session(status)
  if not M.current then return end

  M.current.status = status or "done"
  M.current.finished_at = os.time()

  store.save(M.current)
end

-----------------------------------------------------
-- CLEAR
-----------------------------------------------------
function M.clear()
  M.current = nil
end

return M

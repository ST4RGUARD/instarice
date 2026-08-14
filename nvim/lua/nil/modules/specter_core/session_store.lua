local M = {}

local uv = vim.loop

local dir = vim.fn.stdpath("data") .. "/claude_sessions"

-----------------------------------------------------
-- ENSURE DIR EXISTS
-----------------------------------------------------
local function ensure_dir()
  if uv.fs_stat(dir) then return end
  uv.fs_mkdir(dir, 493) -- 0755
end

-----------------------------------------------------
-- SAVE SESSION
-----------------------------------------------------
function M.save(session)
  ensure_dir()

  if not session or not session.id then return end

  local path = dir .. "/" .. session.id .. ".json"

  local file = io.open(path, "w")
  if not file then return end

  file:write(vim.json.encode(session))
  file:close()
end

-----------------------------------------------------
-- LOAD SESSION
-----------------------------------------------------
function M.load(id)
  local path = dir .. "/" .. id .. ".json"

  local file = io.open(path, "r")
  if not file then return nil end

  local content = file:read("*a")
  file:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok then return nil end

  return decoded
end

-----------------------------------------------------
-- LIST SESSIONS
-----------------------------------------------------
function M.list()
  ensure_dir()

  local files = vim.fn.glob(dir .. "/*.json", false, true)

  local sessions = {}
  for _, f in ipairs(files) do
    table.insert(sessions, vim.fn.fnamemodify(f, ":t:r"))
  end

  return sessions
end

return M

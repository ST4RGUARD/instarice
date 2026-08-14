local M = {}

local function normalize(text)
  return (text or ""):lower()
end

local function extract_file(text)
  local file = text:match("([%w%-_%.]+%.%a+)")
  return file
end

local function extract_project(text)
  local q = normalize(text)
  return q:match("inside%s+the%s+([/%w%-_%.]+)")
      or q:match("inside%s+([/%w%-_%.]+)")
      or q:match("in%s+the%s+([/%w%-_%.]+)")
      or q:match("%s+in%s+([/%w%-_%.]+)$")
      or q:match("directory%s+([/%w%-_%.]+)")
end

-- Help trigger phrases — anything that sounds like "what can you do"
local HELP_PHRASES = {
  "^help$", "^help tools$", "^help me$", "^list tools$",
  "^list commands$", "^what can you do", "^what commands",
  "^how can you help", "^what do you do", "^capabilities",
  "^show commands", "^show tools", "^commands$", "^tools$",
  "^menu$", "^options$",
}

local function is_help_request(text)
  local t = normalize(text)
  for _, pat in ipairs(HELP_PHRASES) do
    if t:match(pat) then return true end
  end
  return false
end

-- Extract the target symbol/file from a query, stripping leading action verbs
-- so "read api.lua" → "api.lua", "find usages of foo" → "foo"
local STRIP_VERBS = {
  "^read%s+", "^open%s+", "^show%s+me%s+", "^show%s+",
  "^list%s+", "^display%s+", "^find%s+all%s+usages%s+of%s+",
  "^find%s+usages%s+of%s+", "^find%s+all%s+", "^find%s+",
  "^search%s+for%s+", "^search%s+", "^look%s+for%s+",
  "^explain%s+", "^summarize%s+", "^what%s+does%s+",
}

function M.extract_query(text)
  local t = text:gsub("^claude,%s*", ""):gsub("^ai,%s*", "")
  for _, verb in ipairs(STRIP_VERBS) do
    local stripped = t:match(verb .. "(.+)$")
    if stripped and stripped ~= "" then return stripped end
  end
  return t
end

local function detect_action(text)
  text = normalize(text)
  -- Help / discovery (checked first so "help" doesn't fall through to search)
  if is_help_request(text) then return "help" end
  -- Priority detection
  if text:find("rename") then return "rename" end
  if text:find("replace") or text:find("change word") then return "edit" end
  if text:find("buffer") or text:find("open files") then return "list_buffers" end
  -- Multi-step generation: "help me write", "implement", "create similar", "generate"
  if text:find("help me write") or text:find("help me implement")
     or text:find("help me create") or text:find("help me get started")
     or text:find("similar to") or text:find("based on")
     or text:find("implement") or text:find("generate")
     or (text:find("create") and text:find("class"))
     or (text:find("write") and text:match("[%w_]+%.[%a]+")) then
    return "generate"
  end
  -- read/open/show with a filename → read action
  if (text:match("^read%s+") or text:match("^open%s+") or text:match("^show%s+"))
     and text:match("[%w%-_%.]+%.[%a]+") then return "read" end
  if text:find("explain") or text:find("what does") or text:find("examine") then return "explain" end
  if text:find("summarize") then return "summarize" end
  if text:find("refactor") then return "refactor" end
  if text:find("search") or text:find("find") then return "search" end

  return "search" -- Fallback
end

function M.parse(text)
  if not text or text == "" then return nil end
  local clean_text = text:gsub("^claude,%s*", ""):gsub("^ai,%s*", "")
  local action = detect_action(text)

  return {
    raw = text,
    action = action,
    intent = action, -- Planner looks for .intent
    target = {
      file = extract_file(clean_text),
      project = extract_project(clean_text),
    },
    symbol = text:match("symbol%s+([%w_]+)"),
    semantic_hint = { query = clean_text }
  }
end

return M

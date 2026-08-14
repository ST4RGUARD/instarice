local M = {}

local lsp = vim.lsp

-----------------------------------------------------
-- GET CALL HIERARCHY (SAFE WRAPPER)
-----------------------------------------------------
local function request(method, params, bufnr)
  local clients = lsp.get_clients({ bufnr = bufnr })

  if not clients or #clients == 0 then
    return nil
  end

  local client = clients[1]

  local result = nil

  client.request(method, params, function(err, res)
    if err then return end
    result = res
  end, bufnr)

  vim.wait(200)

  return result
end

-----------------------------------------------------
-- OUTGOING CALLS (function → what it calls)
-----------------------------------------------------
function M.outgoing(bufnr, position)
  return request("callHierarchy/outgoingCalls", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = position,
  }, bufnr)
end

-----------------------------------------------------
-- INCOMING CALLS (what calls this function)
-----------------------------------------------------
function M.incoming(bufnr, position)
  return request("callHierarchy/incomingCalls", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    position = position,
  }, bufnr)
end

return M

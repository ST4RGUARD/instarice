local M = {}

local clients = vim.lsp.get_clients()

-----------------------------------------------------
-- FIND CLIENT FOR BUFFER
-----------------------------------------------------
local function get_client(bufnr)
  bufnr = bufnr or 0

  local clients = vim.lsp.get_clients({ bufnr = bufnr })

  if #clients == 0 then
    return nil
  end

  return clients[1]
end

-----------------------------------------------------
-- FIND DEFINITIONS
-----------------------------------------------------
function M.definition(bufnr, pos)
  local client = get_client(bufnr)
  if not client then return {} end

  local params = vim.lsp.util.make_position_params()

  local result = vim.lsp.buf_request_sync(
    bufnr,
    "textDocument/definition",
    params,
    1000
  )

  return result
end

-----------------------------------------------------
-- FIND REFERENCES
-----------------------------------------------------
function M.references(bufnr)
  local client = get_client(bufnr)
  if not client then return {} end

  local params = vim.lsp.util.make_position_params()
  params.context = { includeDeclaration = false }

  local result = vim.lsp.buf_request_sync(
    bufnr,
    "textDocument/references",
    params,
    2000
  )

  return result
end

-----------------------------------------------------
-- DOCUMENT SYMBOLS
-----------------------------------------------------
function M.document_symbols(bufnr)
  local client = get_client(bufnr)
  if not client then return {} end

  local result = vim.lsp.buf_request_sync(
    bufnr,
    "textDocument/documentSymbol",
    vim.lsp.util.make_position_params(),
    2000
  )

  return result
end

-----------------------------------------------------
-- WORKSPACE SYMBOL SEARCH
-----------------------------------------------------
function M.workspace_symbols(query)
  local result = vim.lsp.buf_request_sync(
    0,
    "workspace/symbol",
    { query = query },
    3000
  )

  return result
end

return M

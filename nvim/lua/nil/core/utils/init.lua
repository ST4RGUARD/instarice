local M = {}

-- ╭──────────────────────────────────────────────────────────╮
-- │ 📂 1. Buffer Directory Resolver (Oil Contextualizer)     │
-- ╰──────────────────────────────────────────────────────────╯
function M.get_buffer_dir()
  local bufname = vim.api.nvim_buf_get_name(0)
  local ft = vim.bo.filetype

  if ft == 'oil' then
    return bufname:gsub('^oil://', '')
  elseif bufname ~= '' then
    return vim.fn.expand '%:p:h'
  else
    return vim.uv.cwd() -- Modern Neovim api replacement for vim.loop.cwd()
  end
end

-- ╭──────────────────────────────────────────────────────────╮
-- │ 🐍 2. Python Virtual Environment Target Resolution       │
-- ╰──────────────────────────────────────────────────────────╯
function M.get_project_python()
  local start_dir = vim.fn.expand '%:p:h'

  -- Enhanced: Removed type restrictions to catch root markers accurately
  local root_path = vim.fs.find({ '.venv', 'pyproject.toml', '.git' }, {
    upward = true,
    path = start_dir,
  })[1]

  if not root_path then
    vim.notify('[python_root] Could not find project root containing markers', vim.log.levels.ERROR)
    return nil
  end

  -- Flatten the path backward if it directly evaluated the hidden directory line
  if vim.endswith(root_path, '.venv') then
    root_path = vim.fn.fnamemodify(root_path, ':h')
  elseif vim.fn.filereadable(root_path) == 1 then
    root_path = vim.fn.fnamemodify(root_path, ':p:h')
  end

  local python_path = root_path .. '/.venv/bin/python'

  if vim.fn.filereadable(python_path) == 0 then
    vim.notify('[python_root] Python executable not found at: ' .. python_path, vim.log.levels.ERROR)
    return nil
  end

  return python_path
end

-- ╭──────────────────────────────────────────────────────────╮
-- │ 🦀 3. Rust Workspace Project Root Anchor                 │
-- ╰──────────────────────────────────────────────────────────╯
function M.rust_root()
  local buf_path = vim.api.nvim_buf_get_name(0)
  local start_dir = vim.fn.fnamemodify(buf_path, ':p:h')
  local cargo_toml = vim.fn.findfile('Cargo.toml', start_dir .. ';')
  if cargo_toml == '' then
    vim.notify('Cargo.toml not found', vim.log.levels.ERROR)
    return vim.uv.cwd()
  end
  return vim.fn.fnamemodify(cargo_toml, ':p:h')
end

-- ╭──────────────────────────────────────────────────────────╮
-- │ 🚀 4. LSP Core Capabilities Attach Interceptor            │
-- ╰──────────────────────────────────────────────────────────╯
function M.common_on_attach(client, bufnr)
  -- De-duplicate attachment threads cleanly
  for _, c in ipairs(vim.lsp.get_clients { bufnr = bufnr }) do
    if c.name == client.name and c.id ~= client.id then
      vim.schedule(function()
        vim.lsp.stop_client(client.id)
      end)
      return
    end
  end

  local opts = { buffer = bufnr, silent = true }

  if client.name == 'gopls' then
    client.server_capabilities.documentFormattingProvider = false
  end

  -- Global LSP Core Mappings
  opts.desc = 'Show LSP references'
  vim.keymap.set('n', 'gR', '<cmd>Telescope lsp_references<CR>', opts)

  opts.desc = 'Go to declaration'
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)

  opts.desc = 'Show LSP definitions'
  vim.keymap.set('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', opts)

  opts.desc = 'Show LSP implementations'
  vim.keymap.set('n', 'gi', '<cmd>Telescope lsp_implementations<CR>', opts)

  opts.desc = 'Show LSP type definitions'
  vim.keymap.set('n', 'gt', '<cmd>Telescope lsp_type_definitions<CR>', opts)

  opts.desc = 'See available code actions'
  vim.keymap.set({ 'n', 'v' }, '<leader>gra', vim.lsp.buf.code_action, opts)

  opts.desc = 'Smart rename'
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)

  opts.desc = 'Show buffer diagnostics'
  vim.keymap.set('n', '<leader>D', '<cmd>Telescope diagnostics bufnr=0<CR>', opts)

  opts.desc = 'Show line diagnostics'
  vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)

  opts.desc = 'Show documentation for what is under cursor'
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)

  opts.desc = 'Restart LSP'
  vim.keymap.set('n', '<leader>rs', ':LspRestart<CR>', opts)

  vim.keymap.set('i', '<C-h>', vim.lsp.buf.signature_help, opts)
end

return M

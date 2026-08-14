local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, 'CurSearch', { bg = 'green', fg = 'black', bold = true })

  vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function()
      vim.api.nvim_set_hl(0, 'CurSearch', { bg = 'green', fg = 'black', bold = true })
    end,
  })

  vim.api.nvim_create_autocmd('BufReadPost', {
    pattern = '*.py',
    callback = function()
      local lines = vim.api.nvim_buf_get_lines(0, 0, 20, false)
      local has_markdown_cell = false
      for _, line in ipairs(lines) do
        if line:match '^# %% %[markdown%]' then
          has_markdown_cell = true
          break
        end
      end
      if has_markdown_cell then
        print 'Markdown cell found — enabling render-markdown'
        require('render-markdown').enable()
        require('render-markdown').update()
      else
        require('render-markdown').disable()
      end
    end,
  })

  -- Native Auto-format on save for specified languages
  vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = {
      '*.go',
      '*.rs',
      '*.py',
      '*.rb',
      '*.c',
      '*.cpp',
      '*.h',
      '*.hpp',
      '*.java',
      '*.js',
      '*.ts',
      '*.jsx',
      '*.tsx',
      '*.lua',
      '*.sh',
      '*.zsh',
      '*.fish',
      '*.html',
      '*.css',
      '*.scss',
      '*.json',
      '*.yaml',
      '*.yml',
    },
    callback = function(args)
      require('conform').format {
        bufnr = args.buf,
        async = false,
        lsp_fallback = true,
        timeout_ms = 1000,
      }
    end,
  })
end

return M

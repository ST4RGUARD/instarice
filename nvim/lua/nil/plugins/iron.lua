return {
  'hkupty/iron.nvim',
  config = function()
    local iron = require 'iron.core'
    local utils = require 'nil.core.utils'

    -- Dedent lines by removing minimal common indentation
    local function dedent_lines(lines)
      local min_indent = nil
      for _, line in ipairs(lines) do
        if line:match '%S' then
          local leading = line:match '^(%s*)'
          if not min_indent or #leading < min_indent then
            min_indent = #leading
          end
        end
      end

      if not min_indent or min_indent == 0 then
        return lines
      end

      local dedented = {}
      for i, line in ipairs(lines) do
        if #line >= min_indent then
          dedented[i] = line:sub(min_indent + 1)
        else
          dedented[i] = line
        end
      end

      return dedented
    end

    -- Helper to send code lines strictly to the persistent Python REPL
    local function send_code_lines(_, lines)
      local dedented = dedent_lines(lines)
      local non_blank_lines = {}
      for _, line in ipairs(dedented) do
        if line:match '%S' then
          table.insert(non_blank_lines, line)
        end
      end

      if #non_blank_lines == 0 then
        return
      end

      -- Instead of calling repl_for (which creates/switches panes),
      -- we use the raw send command. As long as the REPL window
      -- is already open, iron will route to the last active Python REPL.
      iron.send('python', non_blank_lines)
    end

    iron.setup {
      config = {
        repl_definition = {
          python = {
            command = function()
              local dir = utils.get_buffer_dir()
              local venv_python = dir .. '/.venv/bin/python'
              local venv_ipython = dir .. '/.venv/bin/ipython'

              -- Set image rendering environment variables dynamically on REPL startup
              vim.env.IPYTHON_ICAT_AUTO = '1'
              vim.env.IPYTHON_ICAT_PLACEHOLDER = '1'
              vim.env.IPYTHON_ICAT_TRANSFER_MODE = 'stream'

              -- Case 1: Local .venv has IPython. Use uv run --with to inject dependencies.
              if vim.fn.executable(venv_ipython) == 1 then
                return { 'uv', 'run', '--with', 'ipython-icat', '--with', 'Pillow', venv_ipython, '--no-banner', '--no-autoindent' }

                -- Case 2: Local .venv only has basic Python. Inject everything + standalone ipython.
              elseif vim.fn.executable(venv_python) == 1 then
                return {
                  'uv',
                  'run',
                  '--with',
                  'ipython',
                  '--with',
                  'ipython-icat',
                  '--with',
                  'Pillow',
                  'ipython',
                  '--no-banner',
                  '--no-autoindent',
                }
              end

              -- Case 3: No local .venv found at all. Fallback to global uv execution block.
              return { 'uv', 'run', '--with', 'ipython-icat', '--with', 'Pillow', 'ipython', '--no-banner', '--no-autoindent' }
            end,
          },
        },
        repl_open_cmd = 'vertical botright 80 split',
      },
      keymaps = {
        send_motion = '<leader>sc',
        send_line = '<leader>sl',
        send_file = '<leader>sf',
        send_mark = '<leader>sm',
        mark_motion = '<leader>mc',
        mark_visual = '<leader>mc',
        remove_mark = '<leader>md',
        cr = '<leader>s<cr>',
        interrupt = '<leader>s<space>',
        exit = '<leader>sq',
        clear = '<leader>cl',
      },
    }

    -- Restart Python REPL
    vim.keymap.set('n', '<leader>rr', function()
      local iron = require 'iron.core'
      pcall(function()
        iron.send('python', { 'exit()' })
      end)
      pcall(iron.close_repl)
      vim.defer_fn(function()
        iron.repl_for 'python'
      end, 200)
    end, { desc = 'Restart Python REPL (reliable)' })

    -- Clear Python REPL screen
    vim.keymap.set('n', '<leader>cc', function()
      iron.send('python', { '%clear' })
    end, { desc = 'Send %clear to Python REPL' })

    -- Send Python cell between # %% markers
    local function send_python_cell()
      local start = vim.fn.search('# %%', 'bnW')
      if start == 0 then
        start = 1
      end
      local finish = vim.fn.search('# %%', 'nW')
      if finish == 0 then
        finish = vim.fn.line '$' + 1
      end
      local lines = vim.fn.getline(start, finish - 1)
      send_code_lines(nil, lines)
    end

    vim.keymap.set('n', '<leader>sb', send_python_cell, { desc = 'Send Python Cell to REPL' })

    -- Send current fenced python block inside markdown file
    function SendCurrentPythonBlock()
      local bufnr = vim.api.nvim_get_current_buf()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local start_line, end_line

      for i = cursor[1] - 1, 0, -1 do
        if lines[i]:match '^```python%s*$' then
          start_line = i + 1
          break
        end
      end
      if not start_line then
        print 'No starting ```python block found'
        return
      end

      for i = start_line, #lines do
        if lines[i]:match '^```%s*$' then
          end_line = i - 1
          break
        end
      end
      if not end_line then
        print 'No closing ``` found'
        return
      end

      local block = vim.list_slice(lines, start_line, end_line)
      while block[1] and block[1]:match '^%s*$' do
        table.remove(block, 1)
      end
      while block[#block] and block[#block]:match '^%s*$' do
        table.remove(block, #block)
      end

      send_code_lines(nil, block)
    end

    -- Visual selection
    vim.keymap.set('x', '<leader>sc', function()
      local start_line = vim.fn.line "'<"
      local end_line = vim.fn.line "'>"
      local lines = vim.fn.getline(start_line, end_line)
      send_code_lines(nil, lines)
    end, { desc = 'Send dedented visual selection to REPL' })

    -- Map <leader>ip to send current fenced python block in markdown
    vim.api.nvim_set_keymap('n', '<leader>ip', ':lua SendCurrentPythonBlock()<CR>', { noremap = true, silent = true })

    -- Autocmd for markdown filetype
    vim.api.nvim_create_autocmd('FileType', {
      pattern = 'markdown',
      callback = function()
        vim.keymap.set('n', '<leader>r', function()
          iron.repl_for 'python'
        end, { buffer = true })
        vim.keymap.set('n', '<leader>ip', ':lua SendCurrentPythonBlock()<CR>', { buffer = true })
      end,
    })
  end,
}

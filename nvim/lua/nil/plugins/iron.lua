return {
  "hkupty/iron.nvim",
  config = function()
    local iron = require("iron.core")

    -- Dedent lines by removing minimal common indentation
    local function dedent_lines(lines)
      local min_indent = nil
      for _, line in ipairs(lines) do
        if line:match("%S") then
          local leading = line:match("^(%s*)")
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

    -- Helper to send code lines to the appropriate REPL
    local function send_code_lines(ft, lines)
      local dedented = dedent_lines(lines)

      -- Filter out blank lines completely
      local non_blank_lines = {}
      for _, line in ipairs(dedented) do
        if line:match("%S") then -- Line contains non-whitespace
          table.insert(non_blank_lines, line)
        end
      end

      if #non_blank_lines == 0 then
        print("No non-blank lines to send to REPL")
        return
      end

      if ft == "markdown" then
        iron.send("python", non_blank_lines)
      else
        iron.send(ft, non_blank_lines)
      end
    end

    iron.setup {
      config = {
        repl_definition = {
          python = {
            command = { "rye", "run", "ipython", "--no-banner", "--no-autoindent" }
          },
          preferred = {
            python = "python",
          },
        },
        repl_open_cmd = "vertical botright 80 split",
      },
      keymaps = {
        send_motion = "<leader>sc",
        -- visual_send is replaced by a custom keymap below
        send_line = "<leader>sl",
        send_file = "<leader>sf",
        send_mark = "<leader>sm",
        mark_motion = "<leader>mc",
        mark_visual = "<leader>mc",
        remove_mark = "<leader>md",
        cr = "<leader>s<cr>",
        interrupt = "<leader>s<space>",
        exit = "<leader>sq",
        clear = "<leader>cl",
      },
    }

    -- Restart Python REPL
    vim.keymap.set("n", "<leader>rr", function()
      iron.close_repl()
      vim.defer_fn(function()
        iron.repl_for("python", true)
      end, 100)
    end, { desc = "Restart Python REPL" })

    -- Clear Python REPL screen
    vim.keymap.set("n", "<leader>cc", function()
      iron.send("python", { "%clear" })
    end, { desc = "Send %clear to Python REPL" })

    -- Send Python cell between # %% markers
    local function send_python_cell()
      local start = vim.fn.search("# %%", "bnW")
      if start == 0 then start = 1 end
      local finish = vim.fn.search("# %%", "nW")
      if finish == 0 then finish = vim.fn.line("$") + 1 end

      local lines = vim.fn.getline(start, finish - 1)
      send_code_lines("python", lines)
    end

    vim.keymap.set("n", "<leader>sb", send_python_cell, { desc = "Send Python Cell to REPL" })

    -- Send current fenced python block inside markdown file
    function SendCurrentPythonBlock()
      local bufnr = vim.api.nvim_get_current_buf()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      local start_line, end_line
      for i = cursor[1] - 1, 0, -1 do
        if lines[i]:match("^```python%s*$") then
          start_line = i + 1
          break
        end
      end
      if not start_line then
        print("No starting ```python block found")
        return
      end

      for i = start_line, #lines do
        if lines[i]:match("^```%s*$") then
          end_line = i - 1
          break
        end
      end
      if not end_line then
        print("No closing ``` found")
        return
      end

      local block = vim.list_slice(lines, start_line, end_line)
      -- Trim leading and trailing empty lines
      while block[1] and block[1]:match("^%s*$") do table.remove(block, 1) end
      while block[#block] and block[#block]:match("^%s*$") do table.remove(block, #block) end

      send_code_lines("markdown", block)
    end

    -- Visual selection sends dedented code to REPL with correct ft
    vim.keymap.set("x", "<leader>sc", function()
      local ft = vim.bo.filetype
      local start_line = vim.fn.line("'<")
      local end_line = vim.fn.line("'>")
      local lines = vim.fn.getline(start_line, end_line)
      send_code_lines(ft, lines)
    end, { desc = "Send dedented visual selection to REPL" })

    -- Map <leader>ip to send current fenced python block in markdown
    vim.api.nvim_set_keymap("n", "<leader>ip", ":lua SendCurrentPythonBlock()<CR>", { noremap = true, silent = true })

    -- Autocmd for markdown filetype keymaps
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        -- Open IPython REPL manually with <leader>r
        vim.keymap.set("n", "<leader>r", function()
          iron.repl_for("python")
        end, { buffer = true })

        -- Send fenced python block in markdown with <leader>ip
        vim.keymap.set("n", "<leader>ip", ":lua SendCurrentPythonBlock()<CR>", { buffer = true })
      end,
    })
  end,
}

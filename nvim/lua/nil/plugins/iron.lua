return {
  "hkupty/iron.nvim",
  config = function()
    local iron = require("iron.core")

    iron.setup {
      config = {
        -- Define REPL commands per filetype
        repl_definition = {
          python = {
            command = { "ipython", "--no-banner" }
          },
          preferred = {
            python = "python",
          },
          -- add more if you want (like julia, R, etc)
        },
        repl_open_cmd = "vertical botright 80 split", -- open REPL in vertical split
      },
      keymaps = {
        send_motion = "<leader>sc",     -- send motion/text
        visual_send = "<leader>sc",     -- send visual selection
        send_line = "<leader>sl",       -- send current line
        send_file = "<leader>sf",       -- send whole file
        send_mark = "<leader>sm",       -- send mark
        mark_motion = "<leader>mc",     -- mark motion
        mark_visual = "<leader>mc",     -- mark visual selection
        remove_mark = "<leader>md",     -- remove mark
        cr = "<leader>s<cr>",           -- send carriage return (enter)
        interrupt = "<leader>s<space>", -- interrupt REPL
        exit = "<leader>sq",            -- exit REPL
        clear = "<leader>cl",           -- clear REPL buffer
      },
    }
    -- for python file
    -- reset buffer
    vim.keymap.set("n", "<leader>rr", function()
      iron.close_repl()
      vim.defer_fn(function()
        iron.repl_for("python", true)
      end, 100)
    end, { desc = "Restart Python REPL" })

    -- clear screen
    vim.keymap.set("n", "<leader>cc", function()
      require("iron.core").send("python", { "%clear" })
    end, { desc = "Send %clear to Python REPL" })

    local function send_python_cell()
      local start = vim.fn.search("# %%", "bnW")
      if start == 0 then start = 1 end
      local finish = vim.fn.search("# %%", "nW")
      if finish == 0 then finish = vim.fn.line("$") end

      local lines = vim.fn.getline(start + 1, finish - 1)
      iron.send(nil, lines)
    end

    vim.keymap.set("n", "<leader>sb", send_python_cell, { desc = "Send Python Cell to REPL" })

    -- for jupyter notebook markdown
    -- Detect and send current fenced python code block
    function SendCurrentPythonBlock()
      local start_line = nil
      local end_line = nil
      local bufnr = vim.api.nvim_get_current_buf()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

      -- Search upward for the start of a python code block
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

      -- Search downward for the end of the code block
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

      local code_block = vim.list_slice(lines, start_line, end_line)
      iron.send("python", code_block)
    end

    vim.api.nvim_set_keymap("n", "<leader>ip", ":lua SendCurrentPythonBlock()<CR>", { noremap = true, silent = true })

    -- === Autocmd for Markdown files ===
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "markdown",
      callback = function()
        -- Open IPython manually instead of :IronRepl
        vim.keymap.set("n", "<leader>r", function()
          iron.repl_for("python") -- <== force REPL for python
        end, { buffer = true })

        -- Send fenced python block
        vim.keymap.set("n", "<leader>ip", ":lua SendCurrentPythonBlock()<CR>", { buffer = true })
      end
    })
  end,
}

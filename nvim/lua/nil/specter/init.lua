local M = {}

local chat      = require("nil.modules.specter_core.chat")
local agent     = require("nil.modules.specter_core.agent")
local agent_ui  = require("nil.modules.specter_core.agent_ui")
local inline    = require("nil.modules.specter_core.inline")

-----------------------------------------------------
-- STATE GUARD
-----------------------------------------------------
local initialized = false

-----------------------------------------------------
-- BOOTSTRAP CORE
-----------------------------------------------------
local function bootstrap(config)
  config = config or {}
  if initialized then return end
  initialized = true

  if chat and chat.setup then
    chat.setup({
      chat_model     = config.chat_model    or "claude-opus-4-6",
      refactor_model = config.refactor_model or "claude-opus-4-6",
    })
  end
end

-----------------------------------------------------
-- KEYMAPS + COMMANDS
-----------------------------------------------------
local function register_keymaps()

  -- ── Chat ──────────────────────────────────────
  vim.keymap.set("n", "<leader>cm", chat.prompt,     { desc = "Specter: Open chat" })
  vim.keymap.set("n", "<leader>cc", chat.fresh_chat, { desc = "Specter: Fresh chat" })

  -- ── Agent ─────────────────────────────────────
  vim.keymap.set("n", "<leader>aa", function()
    agent_ui.run()
  end, { desc = "Specter: Open agent UI" })

  vim.api.nvim_create_user_command("SpecterAgentUI", function()
    agent_ui.run()
  end, { desc = "Open Specter agent UI" })

  vim.api.nvim_create_user_command("SpecterAgent", function(opts)
    local input = table.concat(opts.fargs, " ")
    if input == "" then
      print("Usage: :SpecterAgent <task>")
      return
    end
    agent.run(input)
  end, { nargs = "+" })

  vim.api.nvim_create_user_command("SpecterAgentStop", function()
    agent.stop()
  end, {})

  -- ── Inline refactor / fix (visual mode) ───────
  vim.api.nvim_create_user_command("SpecterRefactor", function(opts)
    inline.refactor_selection(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?", range = true, desc = "Specter: Refactor selection (diff)" })

  vim.api.nvim_create_user_command("SpecterFix", function(opts)
    inline.refactor_inplace(opts.args ~= "" and opts.args or nil)
  end, { nargs = "?", range = true, desc = "Specter: Fix selection (in place)" })

  vim.api.nvim_create_user_command("SpecterCustom", function(opts)
    local instruction = opts.args ~= "" and opts.args or nil
    if not instruction then
      vim.ui.input({ prompt = "Specter instruction: " }, function(inp)
        if inp and inp ~= "" then inline.refactor_selection(inp) end
      end)
    else
      inline.refactor_selection(instruction)
    end
  end, { nargs = "?", range = true, desc = "Specter: Custom refactor with instruction (diff)" })

  vim.keymap.set("v", "<leader>fd", ":<C-u>SpecterRefactor<CR>", {
    desc = "Specter: Refactor selection (diff)", noremap = true, silent = true,
  })
  vim.keymap.set("v", "<leader>fi", ":<C-u>SpecterFix<CR>", {
    desc = "Specter: Fix selection (in place)", noremap = true, silent = true,
  })
  vim.keymap.set("v", "<leader>fc", ":<C-u>SpecterCustom<CR>", {
    desc = "Specter: Custom refactor (diff)", noremap = true, silent = true,
  })

  -- ── Inline completions (disabled until Sonnet) ─
  vim.keymap.set("n", "<leader>si", function()
    inline.toggle()
  end, { desc = "Specter: Toggle inline completions" })

end

-----------------------------------------------------
-- PUBLIC API
-----------------------------------------------------
function M.setup(config)
  bootstrap(config)
  register_keymaps()
end

return M

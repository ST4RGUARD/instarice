-----------------------------------------------------
-- help.lua
-- Single source of truth for what Specter can do.
-- Referenced by tools.lua and renderable in the UI.
-----------------------------------------------------
local M = {}

M.commands = {
  {
    category = "Search & Read",
    entries = {
      {
        command = "find <thing>",
        examples = { "find authenticate", "find all usages of parse_request", "search for config" },
        description = "Search the project for a symbol, string, or concept.",
      },
      {
        command = "read <file>",
        examples = { "read api.lua", "read main.rs" },
        description = "Read and display the contents of a file.",
      },
      {
        command = "explain <file or symbol>",
        examples = { "explain api.lua", "what does core_model do" },
        description = "Summarize a file or symbol using the LLM teacher.",
      },
    }
  },
  {
    category = "Edit",
    entries = {
      {
        command = "replace <word> with <word>",
        examples = {
          "replace foo with bar",
          "replace nil with rocket recursively",
          "replace authenticate with verify in all files",
        },
        description = "Find and replace a word. Add 'recursively', 'in all files', or 'across the project' to go project-wide. Word-boundary safe — won't match substrings.",
      },
      {
        command = "rename <symbol> to <symbol>",
        examples = {
          "rename create_fruit_salad to make_fruit_salad",
          "rename function authenticate to verify_user",
          "rename method parse to handle",
        },
        description = "Cross-file symbol rename. Uses ripgrep + LSP to find every reference across all languages (Rust, Go, Python, Ruby, JS, C, C++, Lua) and stages patches for review.",
      },
    }
  },
  {
    category = "Workspace & Patches",
    entries = {
      {
        command = "apply / commit / looks good",
        examples = { "apply", "commit", "looks good" },
        description = "Commit all staged patches to disk.",
      },
      {
        command = "cancel / undo / clear",
        examples = { "cancel", "undo", "clear" },
        description = "Discard all staged patches without writing anything.",
      },
    }
  },
  {
    category = "Session",
    entries = {
      {
        command = ":SpecterSession",
        examples = { ":SpecterSession" },
        description = "Print the current session (steps, checkpoints, status).",
      },
      {
        command = ":SpecterSessions",
        examples = { ":SpecterSessions" },
        description = "List all saved session IDs.",
      },
      {
        command = ":SpecterLoadSession <id>",
        examples = { ":SpecterLoadSession 1712345678" },
        description = "Load and inspect a past session by ID.",
      },
      {
        command = ":SpecterRewind <step>",
        examples = { ":SpecterRewind 3" },
        description = "Rewind the current session to a specific step.",
      },
    }
  },
}

-----------------------------------------------------
-- RENDER as a flat string for the agent UI log
-----------------------------------------------------
function M.render()
  local out = {
    "",
    "  🧠 Specter — What I can do",
    "  ══════════════════════════════════════════",
    "",
  }

  for _, section in ipairs(M.commands) do
    table.insert(out, "  ── " .. section.category .. " ──")
    table.insert(out, "")
    for _, entry in ipairs(section.entries) do
      table.insert(out, "  ❯ " .. entry.command)
      table.insert(out, "    " .. entry.description)
      table.insert(out, "    Examples:")
      for _, ex in ipairs(entry.examples) do
        table.insert(out, "      • " .. ex)
      end
      table.insert(out, "")
    end
  end

  table.insert(out, "  ══════════════════════════════════════════")
  table.insert(out, "  Tip: Stage changes are shown in a diff view.")
  table.insert(out, "  Hit [Enter] to commit, [q] to keep staged, delete + lines to drop patches.")
  table.insert(out, "")

  return table.concat(out, "\n")
end

return M

return {
  "GCBallesteros/jupytext.nvim",
  lazy = false,             -- ensure the plugin loads immediately
  ft = { "json", "python", "markdown" },  -- trigger on notebook or text files
  config = function()
    require("jupytext").setup({
      style = "markdown",          -- prefer Markdown output
      output_extension = "md",
      force_ft = "markdown",       -- treat opened notebook as Markdown buffer
      using_jupytext_cli = true,
    })

    -- Keymap: manually export to .md if you want
    vim.keymap.set("n", "<leader>jm", function()
      local fname = vim.fn.expand("%:p")
      vim.fn.system({ "jupytext", "--to", "md", fname })
      vim.notify("Jupytext exported to .md", vim.log.levels.INFO)
    end, { desc = "Jupytext: Export .ipynb to Markdown" })
  end,
}

return {
  "GCBallesteros/jupytext.nvim",
  lazy = false,
  ft = { "json", "python", "markdown" },
  config = function()
    require("jupytext").setup({
      style = "markdown",
      output_extension = "md",
      force_ft = "markdown",
      using_jupytext_cli = true,
    })

    -- manually export to .md if you want
    vim.keymap.set("n", "<leader>jm", function()
      local fname = vim.fn.expand("%:p")
      vim.fn.system({ "jupytext", "--to", "md", fname })
      vim.notify("Jupytext exported to .md", vim.log.levels.INFO)
    end, { desc = "Jupytext: Export .ipynb to Markdown" })
  end,
}

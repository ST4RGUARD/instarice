return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      explorer = {
        enabled = true,
        layout = {
          cycle = false,
        }
      },
      quickFile = {
        enabled = true,
        exclude = {"latex"},
      },
      picker = {
        enabled = true,
        matchers = {
          frecency = true,
          cwd_bonus = true,
        },
        formatters = {
          file = {
            filename_first = false,
            filename_only = false,
            icon_width = 2,
          },
        },
        layout = {
          preset = "telescope",
          cycle = false,
        },
        layouts = {
          select = {
            preview = false,
            layout = {
              backdrop = false,
              width = 0.6,
              min_width = 80,
              height = 0.4,
              min_height = 10,
              box = "vertical",
              border = "rounded",
              title = "{title}",
              title_pos = "center",
              { win = "input", height = 1, border = "bottom" },
              { win = "list", border = "none" },
              { win = "preview", title = "{preview}", width = 0.6, height = 0.4, border = "top" },
            },
          },
          telescope = {
            reverse = true,
            layout = {
              box = "horizontal",
              backdrop = false,
              width = 0.8,
              height = 0.9,
              border = "none",
              {
                box = "vertical",
                { win = "list", title = " Results ", title_pos = "center", border = "rounded" },
                { win = "input", height = 1, border = "rounded", title = "{title} {live} {flags}", title_pos = "center" },
              },
            },
          },
          ivy = {
            layout = {
              box = "vertical",
              backdrop = false,
              width = 0,
              height = 0.4,
              position = "bottom",
              border = "top",
              title = " {title} {live} {flags} ",
              title_pos = "left",
              { win = "input", height = 1, border = "bottom" },
              { 
                box = "horizontal",
                { win = "list", border = "none" },
                { win = "preview", title = "{preview}", width = 0.5, border = "left" },
            },
          },
        },
        }
      },
      dashboard = {
        enabled = true,
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
          {
            section = "terminal",
            cmd = "ascii-image-converter /home/nilclass/Pictures/beyonder.jpg -C",
            random = 10,
            pane = 2,
            indent = 4,
            height = 30,
          },
        },
      }
    },
    keys = {
      { "<leader>lg", function() require("snacks").lazygit() end, desc = "Lazygit" },
      { "<leader>gl", function() require("snacks").lazygit.log() end, desc = "Lazygit Logs" },
      { "<leader>es", function() require("snacks").explorer() end, desc = "Open Snacks Explorer" },
      { "<leader>rN", function() require("snacks").rename.rename_file() end, desc = "Fast Rename File" },
      { "<leader>dB", function() require("snacks").bufdelete() end, desc = "Delete or Close Buffer" },

      -- snacks picker
      { "<leader>pf", function() require("snacks").picker.files() end, desc = "Find Files" },
      { "<leader>pk", function() require("snacks").picker.keymaps({ layout = "ivy" }) end, desc = "Searh Keymaps" },

      { "<leader>gbr", function() require("snacks").picker.git_branches({ layout = "select" }) end, desc = "Pick and Switch Git Branches" },
      { "<leader>th", function() require("snacks").picker.colorschemes({ layout = "ivy" }) end, desc = "Pick Colorschemes" },
      { "<leader>vh", function() require("snacks").picker.help() end, desc = "Help Pages" },
    }
  }
}

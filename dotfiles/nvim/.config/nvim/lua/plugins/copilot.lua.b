return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = true, auto_trigger = true },
        panel = { enabled = true },
      })
    end,
  },
  { "zbirenbaum/copilot-cmp", opts = {}, after = { "copilot.lua" } },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = {}, -- This ensures a table is passed
    cmd = "CopilotChat",
    event = "VeryLazy",
  },
}

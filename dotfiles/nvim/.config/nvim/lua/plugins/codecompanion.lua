return {
  "olimorris/codecompanion.nvim",
  version = "^19.0.0",
  opts = {
    -- interactions = {
    --   cli = {
    --     agent = "opencode",
    --     agents = {
    --       opencode = {
    --         cmd = "opencode",
    --         args = {},
    --         description = "OpenCode CLI",
    --         provider = "terminal",
    --       },
    --     },
    --   },
    -- },
    extensions = {
      mcphub = {
        callback = "mcphub.extensions.codecompanion",
        opts = {
          make_vars = true,
          make_slash_commands = true,
          show_result_in_chat = true,
        },
      },
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "ravitemer/mcphub.nvim",
  },
}

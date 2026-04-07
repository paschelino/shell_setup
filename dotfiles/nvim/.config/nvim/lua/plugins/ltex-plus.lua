return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ltex_plus = {
        -- Restrict to markdown only (don't check code, HTML, etc.)
        filetypes = { "markdown" },
        settings = {
          ltex = {
            language = "auto", -- detect per-document; change to "de-DE" if too noisy
            checkFrequency = "save", -- "always" to check as you type, "save" to check on save
            markdown = {
              -- Tell ltex-ls-plus to skip YAML frontmatter nodes
              nodes = { FrontMatter = "ignore" },
            },
            -- Empty dicts ready for you to populate via the
            -- "Add to dictionary" quick fix action inside Neovim
            dictionary = {},
            disabledRules = {},
            hiddenFalsePositives = {},
          },
        },
      },
    },
  },
}

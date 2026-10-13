return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ltex_plus = {
        -- Restrict to markdown only (don't check code, HTML, etc.)
        filetypes = { "markdown" },
        -- No grammar checks in journal notes. Detach only this buffer: stopping
        -- the client would end grammar checks in all other open notes, too.
        on_attach = function(client, bufnr)
          if require("util.zk").is_journal(bufnr) then
            vim.schedule(function()
              vim.lsp.buf_detach_client(bufnr, client.id)
            end)
          end
        end,
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

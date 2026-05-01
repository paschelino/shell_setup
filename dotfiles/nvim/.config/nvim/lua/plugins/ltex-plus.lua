return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ltex_plus = {
        -- Restrict to markdown only (don't check code, HTML, etc.)
        filetypes = { "markdown" },
        on_attach = function(client, bufnr)
          local path = vim.api.nvim_buf_get_name(bufnr)
          local zk_dir = vim.fs.find(".zk", {
            upward = true,
            path = vim.fn.fnamemodify(path, ":h"),
          })[1]
          if zk_dir then
            local notebook_root = vim.fn.fnamemodify(zk_dir, ":h")
            if path:find(notebook_root .. "/0-journals/", 1, true) then
              client:stop()
              return
            end
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

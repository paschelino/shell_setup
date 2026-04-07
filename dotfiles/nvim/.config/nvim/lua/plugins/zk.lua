return {
  "zk-org/zk-nvim",
  name = "zk",
  opts = {
    -- Can be "telescope", "fzf", "fzf_lua", "minipick", "snacks_picker",
    -- or select" (`vim.ui.select`).
    picker = "select",

    lsp = {
      -- `config` is passed to `vim.lsp.start(config)`
      config = {
        name = "zk",
        cmd = { "zk", "lsp" },
        filetypes = { "markdown" },
        on_attach = function(_, bufnr)
          vim.schedule(function()
            -- Guard: don't trigger zen for notes opened in the background
            -- (e.g. picker preloads or link prefetches)
            if vim.api.nvim_get_current_buf() ~= bufnr then
              return
            end
            -- Guard: if zen is already open, leave it — the zen window
            -- already syncs to the current buffer via its BufWinEnter handler
            local zen = require("snacks").zen
            if zen.win and zen.win:valid() then
              return
            end
            zen.zen()
          end)
        end,
      },

      -- automatically attach buffers in a zk notebook that match the given filetypes
      auto_attach = {
        enabled = true,
      },
    },
  },
}

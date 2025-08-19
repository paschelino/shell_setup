-- ~/.config/nvim/lua/plugins/mason.lua
return {
  {
    -- override the default mason.nvim spec
    "mason-org/mason.nvim",
    version = "v2.0.1", -- pin to the new v2.0.0 release
    build = ":MasonUpdate", -- re-run installer after update
    -- you can still pass your Mason settings here if needed:
    opts = {
      ui = {
        border = "rounded",
        icons = { package_installed = "✓", package_pending = "…" },
      },
    },
  },
  {
    -- mason-lspconfig should stay compatible—you can pin it too
    "mason-org/mason-lspconfig.nvim",
    version = "v1.20.0", -- latest v1.x that works with Mason 2
    opts = {
      -- your mason-lspconfig settings (if you customized any)
      ensure_installed = { "ruby_ls", "lua_ls", "pyright" },
    },
  },
}

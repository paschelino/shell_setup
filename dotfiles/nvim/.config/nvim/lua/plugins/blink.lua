-- Disable the completion menu auto-show and ghost text for markdown files.
-- Manual trigger still works if needed.
return {
  "saghen/blink.cmp",
  opts = {
    completion = {
      menu = {
        auto_show = function()
          return vim.bo.filetype ~= "markdown"
        end,
      },
      ghost_text = {
        enabled = function()
          return vim.bo.filetype ~= "markdown"
        end,
      },
    },
  },
}

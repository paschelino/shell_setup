-- Disable the completion menu auto-show for markdown files.
-- Copilot suggestions (via blink-copilot) are also suppressed as a result,
-- since they surface through the same blink.cmp menu.
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

-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt_local.textwidth = 120
vim.opt_local.colorcolumn = "120"

-- Automatically reload buffers when files change on the filesystem.
-- `autoread` alone only triggers in limited scenarios, so the autocmd below
-- calls `checktime` on focus/buffer events to actively detect changes.
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI", "WinEnter" }, {
  pattern = "*",
  callback = function()
    if vim.fn.mode() ~= "c" then
      vim.cmd("checktime")
    end
  end,
})

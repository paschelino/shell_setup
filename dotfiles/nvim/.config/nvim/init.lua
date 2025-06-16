-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Simplified nushell integration that works with terminal buffers
if vim.fn.executable("nu") == 1 then
  vim.o.shell = "nu"
  vim.o.shellcmdflag = "-c"
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
  -- Use simpler pipe/redirect that doesn't interfere with terminal buffers
  vim.o.shellpipe = "| save --raw /dev/stdout"
  vim.o.shellredir = "| save --raw"
end

-- make extra sure rbenv shims are on PATH for all jobs
vim.env.PATH = vim.env.HOME .. "/.rbenv/shims:" .. vim.env.HOME .. "/.rbenv/bin:" .. vim.env.PATH

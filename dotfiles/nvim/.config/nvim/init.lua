-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Optimized nushell integration for seamless terminal experience
if vim.fn.executable("nu") == 1 then
  vim.o.shell = "nu"
  vim.o.shellcmdflag = "-c"
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
  vim.o.shellpipe = "| save --raw"
  vim.o.shellredir = "| save --raw"
  vim.o.shelltemp = false
  -- Set shell type for better integration
  vim.g.is_nushell = true
end

-- make extra sure rbenv shims are on PATH for all jobs
vim.env.PATH = vim.env.HOME .. "/.rbenv/shims:" .. vim.env.HOME .. "/.rbenv/bin:" .. vim.env.PATH

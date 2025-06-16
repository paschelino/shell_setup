-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Simplified nushell integration that works with terminal buffers
if vim.fn.executable("nu") == 1 then
  vim.o.shell = "nu"
  vim.o.shellcmdflag = "-c"
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
  vim.o.shellpipe = "| complete | get stdout | str trim"
  vim.o.shellredir = "| complete | get stdout | str trim"
  vim.o.shelltemp = false
  -- Disable shellslash on all platforms for nushell
  vim.o.shellslash = false
  -- Set shell type for better integration
  vim.g.is_nushell = true
  -- Ensure proper escaping for nushell commands
  vim.g.nushell_no_auto_format = true
end

-- make extra sure rbenv shims are on PATH for all jobs
vim.env.PATH = vim.env.HOME .. "/.rbenv/shims:" .. vim.env.HOME .. "/.rbenv/bin:" .. vim.env.PATH

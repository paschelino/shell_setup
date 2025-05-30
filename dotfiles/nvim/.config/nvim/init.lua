-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

if vim.fn.executable("nu") == 1 then
  vim.o.shell = "/usr/local/bin/nu --login"
  vim.o.shellcmdflag = "-c"
end

-- make extra sure rbenv shims are on PATH for all jobs
vim.env.PATH = vim.env.HOME .. "/.rbenv/shims:" .. vim.env.HOME .. "/.rbenv/bin:" .. vim.env.PATH

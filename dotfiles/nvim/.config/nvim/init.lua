-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Can you make the setup here for nu perfect?
if vim.fn.executable("nu") == 1 then
  vim.o.shell = "nu"
  vim.o.shellcmdflag = "-c"
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
end

-- make extra sure rbenv shims are on PATH for all jobs
vim.env.PATH = vim.env.HOME .. "/.rbenv/shims:" .. vim.env.HOME .. "/.rbenv/bin:" .. vim.env.PATH

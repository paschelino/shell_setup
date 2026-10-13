-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- make extra sure rbenv shims are on PATH for all jobs
vim.env.PATH = vim.env.HOME .. "/.rbenv/shims:" .. vim.env.HOME .. "/.rbenv/bin:" .. vim.env.PATH

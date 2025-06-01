-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local k = vim.keymap

k.set("i", "jj", "<Esc>", { noremap = false })
k.set("i", "jk", "<Esc>", { noremap = false })

-- Copilot:
k.set("i", "<C-l>", 'copilot#Accept("<CR>")', { expr = true, silent = true })

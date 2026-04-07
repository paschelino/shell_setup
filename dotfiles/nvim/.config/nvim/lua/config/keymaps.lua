-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local k = vim.keymap

k.set("i", "jj", "<Esc>", { noremap = false })
k.set("i", "jk", "<Esc>", { noremap = false })

-- In insert mode, make <M-u> act as a dead key for umlauts (mirrors macOS Option+u behaviour)
local umlauts = { a = "ä", o = "ö", u = "ü", A = "Ä", O = "Ö", U = "Ü" }
for key, char in pairs(umlauts) do
  k.set("i", "<M-u>" .. key, char, { desc = "umlaut: " .. char })
end

-- <M-u> alone (not followed by a vowel): no-op, as before
vim.keymap.set({ "n", "v", "x" }, "<M-u>", "<Nop>", { desc = "disabled (umlaut dead key)" })

-- In insert mode, make <M-s> produce ß (mirrors macOS Option+s behaviour).
k.set("i", "<M-s>", "ß", { desc = "umlaut: ß" })

-- Zettelkasten keymaps:
local opts = { noremap = true, silent = false }

-- Create a new note after asking for its title.
vim.api.nvim_set_keymap("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", opts)

-- Open notes.
vim.api.nvim_set_keymap("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", opts)
-- Open notes associated with the selected tags.
vim.api.nvim_set_keymap("n", "<leader>zt", "<Cmd>ZkTags<CR>", opts)

-- Search for the notes matching a given query.
vim.api.nvim_set_keymap(
  "n",
  "<leader>zf",
  "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
  opts
)
-- Search for the notes matching the current visual selection.
vim.api.nvim_set_keymap("v", "<leader>zf", ":'<,'>ZkMatch<CR>", opts)

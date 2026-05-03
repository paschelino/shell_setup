-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local k = vim.keymap

k.set("i", "jj", "<Esc>", { noremap = false })
k.set("i", "jk", "<Esc>", { noremap = false })

-- Also ensure not to undo the last edit by accidentially hitting strg+u in insert mode.
k.set("i", "<C-u>", "<Nop>", { desc = "Disable accidental line-kill" })

-- <M-u> in insert mode: dead key for umlauts. Uses getcharstr() to wait
-- indefinitely for the next keystroke, so this is not subject to timeoutlen
-- (which only applies to statically-defined multi-key mappings). Typing any
-- non-vowel key after <M-u> inserts that key unchanged.
k.set("i", "<M-u>", function()
  local umlauts = { a = "ä", o = "ö", u = "ü", A = "Ä", O = "Ö", U = "Ü" }
  local ch = vim.fn.getcharstr()
  -- Use feedkeys with "n" (no-remap) + "t" (as typed) so the insert happens
  -- exactly at the cursor — this respects autopairs and any other insert-mode
  -- logic. nvim_put would use normal-mode "put-after" semantics and land
  -- outside of auto-closed quote/bracket pairs.
  vim.api.nvim_feedkeys(umlauts[ch] or ch, "nt", true)
end, { desc = "dead key: umlaut" })

-- <M-u> alone (not followed by a vowel): no-op, as before
vim.keymap.set({ "n", "v", "x" }, "<M-u>", "<Nop>", { desc = "disabled (umlaut dead key)" })

-- In insert mode, make <M-s> produce ß (mirrors macOS Option+s behaviour).
k.set("i", "<M-s>", "ß", { desc = "German sharp S: ß" })

-- In insert mode, make <M--> produce – (mirrors macOS Option+- behaviour).
k.set("i", "<M-->", "–", { desc = "Em dash: –" })

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

-- Enable sophisticated speech to text processing for dictation in insert mode.
require("config.dictation")

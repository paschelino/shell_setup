-- ftplugin/markdown.lua
-- Buffer-local settings applied to every Markdown file.
-- This file is sourced automatically by Neovim on the FileType event.

-- Enforce an 80-character line width and show the column ruler.
-- textwidth drives `gq` reflowing and auto-wrap (when fo+=t).
-- colorcolumn draws the visual guide at that column.
vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = "80"

-- Zettelkasten keymaps (zk-nvim) ------------------------------------------
--
-- These buffer-local mappings are only registered when the current file lives
-- inside a zk notebook (identified by an ancestor .zk directory).

if require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
  local function map(...)
    vim.api.nvim_buf_set_keymap(0, ...)
  end
  local opts = { noremap = true, silent = false }

  -- Follow the wiki-link under the cursor (delegates to the zk LSP server).
  map("n", "<CR>", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)

  -- Create a new note in the same directory as the current buffer.
  -- Overrides the global <leader>zn mapping defined in lua/config/keymaps.lua.
  map("n", "<leader>zn", "<Cmd>ZkNew { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>", opts)

  -- Create a new note using the current visual selection as the title.
  map("v", "<leader>znt", ":'<,'>ZkNewFromTitleSelection { dir = vim.fn.expand('%:p:h') }<CR>", opts)

  -- Create a new note using the current visual selection as the body,
  -- prompting separately for a title.
  map(
    "v",
    "<leader>znc",
    ":'<,'>ZkNewFromContentSelection { dir = vim.fn.expand('%:p:h'), title = vim.fn.input('Title: ') }<CR>",
    opts
  )

  -- Open a picker of all notes that link to the current buffer (backlinks).
  map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", opts)

  -- Open a picker of all notes linked from the current buffer (outgoing links).
  map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", opts)

  -- Show a hover preview of the note under the cursor via the LSP server.
  map("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)

  -- Run LSP code actions on the current visual selection (e.g. extract to note).
  map("v", "<leader>za", ":'<,'>lua vim.lsp.buf.range_code_action()<CR>", opts)
end
